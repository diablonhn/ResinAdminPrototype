part of jamp;

abstract class Channel
{
  Logger _logger = new Logger("Channel");

  Map<int,Request> _requestMap = new Map();
  Map<String,Callback> _callbackMap = new Map();

  int _callbackCount = 0;
  int _queryCount = 0;
  String _url;

  Channel(String this._url);

  /**
   * Creates a JAMP channel to the specificed URL.
   */
  static Channel createChannel(String url)
  {
    if (WebSocket.supported) {
      return new WebSocketChannel(url);
    }
    else {
      return new HttpChannel(url);
    }
  }

  void close();
  void reconnect();
  void submitRequest(Request request, {bool isBlocking : true});

  /**
   * Submits a message expecting a response.
   *
   * @param serviceName
   * @param methodName
   * @param args
   * @param fromAddress
   * @param headerMap
   * @param isBlocking true to submit a blocking RPC call, false to do polling
   *
   * @return the response from the service.
   */
  Future<ReplyMessage> query(String serviceName,
                             String methodName,
                             {List args,
                              String fromAddress : "me",
                              Map<String,String> headerMap,
                              bool isBlocking : true})
  {
    int queryId = this._queryCount++;

    QueryMessage msg = new QueryMessage(headerMap,
                                        fromAddress,
                                        queryId,
                                        serviceName,
                                        methodName,
                                        args);

    Request request = createQueryRequest(queryId, msg);

    submitRequest(request, isBlocking : isBlocking);

    return request.getFuture();
  }

  /**
   * Submits a message without expecting a response.
   *
   * @param serviceName
   * @param methodName
   * @param args
   * @param fromAddress
   * @param headerMap
   * @param isBlocking true to submit a blocking RPC call, false to do polling
   *
   * @return true if the message has been sent, error otherwise
   */
  Future<bool> send(String serviceName,
                    String methodName,
                    {List args,
                     String fromAddress : "me",
                     Map<String,String> headerMap,
                     bool isBlocking : true})
  {
    int queryId = _queryCount++;

    SendMessage msg = new SendMessage(headerMap,
                                      serviceName,
                                      methodName,
                                      args);

    Request request = createSendRequest(queryId, msg);

    submitRequest(request, isBlocking : isBlocking);

    return request.getFuture();
  }

  /**
   * Subscribes to the remote service with a local callback.
   *
   * Steps for subscribing to a service:
   * 1. call register() to register your <code>Callback</code>
   * 2. call subscribe() with the callback address returned by register
   * 3. the service's <code>@OnSubscribe</code> method is called
   *
   * @param serviceName
   * @param myCallbackAddress remote callback address for a local callback
   * @param args
   * @param fromAddress
   * @param headerMap
   * @param isBlocking
   */
  Future<ReplyMessage> subscribe(String serviceName,
                                 String myCallbackAddress,
                                 {List args,
                                  String fromAddress : "me",
                                  Map<String,String> headerMap,
                                  bool isBlocking : true})
  {
    int queryId = this._queryCount++;

    SubscribeMessage msg = new SubscribeMessage(headerMap,
                                                fromAddress,
                                                queryId,
                                                serviceName,
                                                myCallbackAddress);

    Request request = createQueryRequest(queryId, msg);

    submitRequest(request, isBlocking : isBlocking);

    return request.getFuture();
  }

  /**
   * Adds this callback to the local list of callbacks.
   *
   * @return the remote callback address for this callback object
   */
  Future<String> registerCallback(Callback callback)
  {
    Future<String> future = getCallbackAddress(callback);

    return future;
  }

  /**
   * Removes this callback from the local list of callbacks.
   */
  void removeCallback(Callback callback)
  {
    String address = null;

    _callbackMap.forEach((String key, Callback cb) {
      if (cb == callback) {
        address = key;
      }
    });

    if (address == null) {
      throw new Exception("callback has not been registered: $callback");
    }

    _callbackMap.remove(address);
  }

  Future<String> getCallbackAddress(Callback cb)
  {
    String serviceName = "channel:";
    String methodName = "publishChannel";

    String id = "/_cb_${this._callbackCount++}";

    Future<ReplyMessage> future = query(serviceName,
                                        methodName,
                                        args : [id]);

    Completer<String> completer = new Completer();

    future.then((ReplyMessage msg) {
      String address = msg.result as String;

      _addCallback(address, cb);

      completer.complete(address);
    });

    return completer.future;
  }

  SendRequest createSendRequest(int queryId, SendMessage msg)
  {
    SendRequest request = new SendRequest(queryId, msg);

    this._requestMap[queryId] = request;

    return request;
  }

  QueryRequest createQueryRequest(int queryId, QueryMessage msg)
  {
    QueryRequest request = new QueryRequest(queryId, msg);

    this._requestMap[queryId] = request;

    return request;
  }

  void _addCallback(String address, Callback cb)
  {
    _callbackMap[address] = cb;
  }

  void _removeCallback(String address)
  {
    _callbackMap.remove(address);
  }

  void onMessageString(String json)
  {
    Message msg = unserialize(json);

    onMessage(msg);
  }

  void onMessageList(List<List> msgList)
  {
    for (List list in msgList) {
      Message msg = unserializeList(list);

      onMessage(msg);
    }
  }

  void onMessage(Message msg)
  {
    if (msg is ReplyMessage) {
      ReplyMessage reply = msg as ReplyMessage;

      int queryId = reply._queryId;
      Request request = removeRequest(queryId);

      if (request == null) {
        _logger.warning("cannot find request for query id: $queryId");
      }

      request.completed(this, reply);
    }
    else if (msg is ErrorMessage) {
      ErrorMessage reply = msg as ErrorMessage;

      int queryId = reply._queryId;
      Request request = removeRequest(queryId);

      if (request == null) {
        _logger.warning("cannot find request for query id: $queryId");
      }

      request.error(this, reply);
    }
    else {
      throw new Exception("unexpected jamp message type: $msg");
    }
  }

  /**
   * Runs periodically to prune requests that have timed out, and invoking
   * error callbacks if applicable.
   */
  void checkRequests()
  {
    List<Request> expiredRequestList = new List();

    this._requestMap.forEach((int queryId, Request request) {
      if (request.isExpired()) {
        expiredRequestList.add(request);
      }
    });

    for (Request request in expiredRequestList) {
      removeRequest(request._queryId);

      request.error(this, "expired request");
    }
  }

  Request removeRequest(int queryId)
  {
    return this._requestMap.remove(queryId);
  }
}

class Request<T>
{
  int _queryId;

  Message _msg;
  DateTime _expirationTime;

  Completer<T> _completer;

  Request(int queryId,
          Message msg,
          {Duration timeout : const Duration(seconds : 5)})
  {
    this._queryId = queryId;
    this._msg = msg;

    this._expirationTime = new DateTime.now().add(timeout);

    this._completer = new Completer<T>();
  }

  int get queryId => _queryId;
  Message get msg => _msg;

  bool isExpired([DateTime now])
  {
    if (now == null) {
      now = new DateTime.now();
    }

    return now.isAfter(this._expirationTime);
  }

  void sent(Channel channel)
  {
  }

  void completed(Channel channel, T value)
  {
    if (! this._completer.isCompleted) {
      this._completer.complete(value);
    }
  }

  void error(Channel channel, Object error)
  {
    if (! this._completer.isCompleted) {
      this._completer.completeError(error);
    }
  }

  Future<T> getFuture() => this._completer.future;
}

class SendRequest extends Request<bool>
{
  SendRequest(int queryId,
              Message msg,
              {Duration timeout : const Duration(seconds : 5)})
              : super(queryId, msg, timeout : timeout);

  @override
  void sent(Channel channel)
  {
    channel.removeRequest(this._queryId);

    if (! this._completer.isCompleted) {
      this._completer.complete(true);
    }
  }
}

class QueryRequest extends Request<ReplyMessage>
{
  QueryRequest(int queryId,
               Message msg,
               {Duration timeout : const Duration(seconds : 5)})
               : super(queryId, msg, timeout : timeout);
}

abstract class Callback
{
  void call(String methodName, {List args});
}
