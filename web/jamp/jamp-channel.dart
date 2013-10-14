part of jamp;

abstract class Channel
{
  /**
   * Creates a JAMP channel to the specified URL.
   */
  Channel create(String url)
  {
    if (WebSocket.supported) {
      return new WebSocketChannel(url);
    }
    else {
      return new HttpChannel(url);
    }
  }

  /**
   * true for AJAX queries to use RPC instead of polling,
   * does not affect WebSockets.
   */
  set isBlocking(bool isBlocking);

  /**
   * Sets the ChannelManager for this channel.
   */
  set manager(ChannelManager manager);

  void close();
  void reconnect();

  void _submitRequest(Request request);
  Request _removeRequest(int queryId);

  /**
   * Submits a message expecting a response.
   *
   * @param serviceName
   * @param methodName
   * @param args
   * @param resultObject unmarshal json result map into this object
   *
   * @return the response from the service
   */
  Future<Object> query(String serviceName,
                       String methodName,
                       {List args,
                        Object resultObject});

  /**
   * Submits a message without expecting a response.
   *
   * @param serviceName
   * @param methodName
   * @param args
   *
   * @return true if the message has been sent, error otherwise
   */
  Future<bool> send(String serviceName,
                    String methodName,
                    {List args});

  /**
   * Subscribes a local callback to the remote service.
   *
   * Steps for subscribing to a service:
   * 1. call registerCallback() to register your object as a callback (locally)
   * 2. call subscribe() with the callback address returned by registerCallback()
   * 3. the service's <code>@OnSubscribe</code> method is called
   *
   * @param serviceName
   * @param myCallbackAddress remote callback address for a local callback
   * @param args
   * @param resultObject unmarshal json result map into this object
   */
  Future<Object> subscribe(String serviceName,
                           String myCallbackAddress,
                           {List args,
                            Object resultObject});

  /**
   * Register this object as a callback locally.
   *
   * @return the remote callback address for this callback object
   */
  Future<String> registerCallback(Object obj);

  /**
   * Removes the object at this address as local callback.
   */
  void removeCallback(String address);
}

abstract class BaseChannel extends Channel
{
  Logger _logger = new Logger("BaseChannel");

  String _url;
  int _callbackCount = 0;
  int _queryCount = 0;

  bool _isBlocking = true;

  Map<int,Request> _requestMap = new Map();
  Map<String,Callback> _callbackMap = new Map();

  ChannelManager _manager;

  /**
   * true for AJAX queries to use RPC instead of polling,
   * does not affect WebSockets.
   */
  @override
  set isBlocking(bool isBlocking) => _isBlocking = isBlocking;

  /**
   * Sets the ChannelManager for this channel.
   */
  @override
  set manager(ChannelManager manager) => _manager = manager;

  BaseChannel._construct(String url)
  {
    _url = url;

    _manager = new BasicChannelManager(this);
  }

  /**
   * Submits a message expecting a response.
   *
   * @param serviceName
   * @param methodName
   * @param args
   * @param resultObject unmarshal json result map into this object
   *
   * @return the response from the service
   */
  @override
  Future<Object> query(String serviceName,
                       String methodName,
                       {List args,
                        Object resultObject})
  {
    if (resultObject != null
        && (resultObject is bool
            || resultObject is num
            || resultObject is String
            || resultObject is List)) {
      throw new Exception("result object must be an object");
    }

    int queryId = this._queryCount++;

    String fromAddress = "me";
    Map<String,String> headerMap = null;

    QueryMessage msg = new QueryMessage(headerMap,
                                        fromAddress,
                                        queryId,
                                        serviceName,
                                        methodName,
                                        args);

    Request request = createQueryRequest(queryId, msg, resultObject);

    _submitRequest(request);

    return request.getFuture();
  }

  /**
   * Submits a message without expecting a response.
   *
   * @param serviceName
   * @param methodName
   * @param args
   *
   * @return true if the message has been sent, error otherwise
   */
  @override
  Future<bool> send(String serviceName,
                    String methodName,
                    {List args})
  {
    int queryId = _queryCount++;

    Map<String,String> headerMap = null;

    SendMessage msg = new SendMessage(headerMap,
                                      serviceName,
                                      methodName,
                                      args);

    Request request = createSendRequest(queryId, msg);

    _submitRequest(request);

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
   * @param resultObject unmarshal json result map into this object
   */
  @override
  Future<Object> subscribe(String serviceName,
                           String myCallbackAddress,
                           {List args,
                            Object resultObject})
  {
    if (resultObject != null
        && (resultObject is bool
            || resultObject is num
            || resultObject is String
            || resultObject is List)) {
      throw new Exception("result object must be an object");
    }

    int queryId = _queryCount++;

    Map<String,String> headerMap = null;
    String fromAddress = "me";

    SubscribeMessage msg = new SubscribeMessage(headerMap,
                                                fromAddress,
                                                queryId,
                                                serviceName,
                                                myCallbackAddress);

    Request request = createQueryRequest(queryId, msg, resultObject);

    _submitRequest(request);

    return request.getFuture();
  }

  /**
   * Adds this callback to the local list of callbacks.
   *
   * @return the remote callback address for this callback object
   */
  @override
  Future<String> registerCallback(Object obj)
  {
    String serviceName = "channel:";
    String methodName = "publishChannel";

    String id = "/_cb_${this._callbackCount++}";

    Future<String> future = query(serviceName,
                                  methodName,
                                  args : [id]);

    return future.then((String address) {
      _addCallback(address, obj);
    });
  }

  /**
   * Removes this callback from the local list of callbacks.
   */
  @override
  void removeCallback(String address)
  {
    _callbackMap.remove(address);
  }

  SendRequest createSendRequest(int queryId, SendMessage msg)
  {
    SendRequest request = new SendRequest(queryId, msg);

    _requestMap[queryId] = request;

    return request;
  }

  QueryRequest createQueryRequest(int queryId,
                                  QueryMessage msg,
                                  Object resultObject)
  {
    QueryRequest request = new QueryRequest(queryId, msg, resultObject);

    _requestMap[queryId] = request;

    return request;
  }

  void completeRequest(Request request, Object value)
  {
    _requestMap.remove(request);

    request.completed(this, value);
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
      Request request = _removeRequest(queryId);

      if (request != null) {
        request.completed(this, reply.result);
      }
      else {
        _logger.warning("cannot find request for query id: $queryId");
      }
    }
    else if (msg is ErrorMessage) {
      ErrorMessage reply = msg as ErrorMessage;

      int queryId = reply._queryId;
      Request request = _removeRequest(queryId);

      if (request != null) {
        request.error(this, reply.result);
      }
      else {
        _logger.warning("cannot find request for query id: $queryId");
      }
    }
/*
    else if (msg is SendMessage) {

    }
    else if (msg is QueryMessage) {

    }
*/
    else {
      _manager.onError(new Exception("unknown message type: $msg"));
    }
  }

  /**
   * Runs periodically to prune requests that have timed out, and invoking
   * error callbacks if applicable.
   */
  void checkRequests()
  {
    List<Request> expiredRequestList = new List();

    _requestMap.forEach((int queryId, Request request) {
      if (request.isExpired()) {
        expiredRequestList.add(request);
      }
    });

    for (Request request in expiredRequestList) {
      _removeRequest(request._queryId);

      request.error(this, "request expired");
    }
  }

  @override
  Request _removeRequest(int queryId)
  {
    return _requestMap.remove(queryId);
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
    _queryId = queryId;
    _msg = msg;

    _expirationTime = new DateTime.now().add(timeout);

    _completer = new Completer<T>();
  }

  int get queryId => _queryId;
  Message get msg => _msg;

  String serialize()
  {
    return _msg.serialize();
  }

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
    if (! _completer.isCompleted) {
      _completer.complete(value);
    }
  }

  void error(Channel channel, Object error)
  {
    if (! _completer.isCompleted) {
      _completer.completeError(error);
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
    channel._removeRequest(_queryId);

    if (! _completer.isCompleted) {
      _completer.complete(true);
    }
  }
}

class QueryRequest extends Request<Object>
{
  Object _resultObject;

  QueryRequest(int queryId,
               Message msg,
               Object resultObject,
               {Duration timeout : const Duration(seconds : 5)})
               : super(queryId, msg, timeout : timeout)
  {
    _resultObject = resultObject;
  }

  @override
  void completed(Channel channel, Object resultValue)
  {
    if (_completer.isCompleted) {
      return;
    }

    try {
      if (_resultObject != null) {
        if (resultValue == null) {
          _completer.complete(null);

          return;
        }
        if (! (resultValue is Map)) {
          throw new Exception("cannot marshal value $resultValue"
                              + " of type ${resultValue.runtimeType}"
                              + " to type ${_resultObject.runtimeType}");
        }

        Map map = resultValue as Map;

        M.InstanceMirror mirror = M.reflect(_resultObject);

        map.forEach((String key, Object value) {
          /*
          // use setter for private fields
          if (key.startsWith("_")) {
            key = key.substring(1);
          }
          */

          Symbol symbol = new Symbol(key);

          value = marshalValue(mirror.type, symbol, value);

          mirror.setField(symbol, value);
        });

        _completer.complete(_resultObject);
      }
      else {
        _completer.complete(resultValue);
      }
    }
    catch (e) {
      _completer.completeError(e);
    }
  }

  Object marshalValue(M.ClassMirror mirror, Symbol symbol, Object value)
  {
    /*
    print("marshalValue1: $symbol, $value, $typeName");

    Map<Symbol, M.MethodMirror> setters = mirror.setters;

    M.MethodMirror method = setters[symbol];

    if (method != null) {
      List<M.ParameterMirror> paramList = method.parameters;
      M.ParameterMirror param = paramList[0];

      String typeName = param.qualifiedName.toString();

      print("marshalValue1: $symbol, $value, $typeName");
    }
    */

    return value;
  }
}

abstract class ChannelManager
{
  Channel _channel;

  ChannelManager(Channel channel)
  {
    _channel = channel;
  }

  /**
   * Called when the channel is opened/reopened
   */
  void onOpen();

  /**
   * Called when the channel is closed unexpectedly
   */
  void onClose(Exception e);

  /**
   * Called when there is an unspecified error with the channel
   */
  void onError(Exception e);
}

class BasicChannelManager extends ChannelManager
{
  Logger _logger = new Logger("BasicChannelManager");

  int _maxRetries;
  int _reconnectIntervalMs;

  int _reconnectCount = 0;

  BasicChannelManager(Channel channel,
                      {int reconnectIntervalMs : 1000 * 5,
                       int maxRetries : 3})
                      : super(channel)
  {
    _maxRetries = maxRetries;
    _reconnectIntervalMs = reconnectIntervalMs;
  }

  @override
  void onOpen()
  {
    _reconnectCount = 0;
  }

  @override
  void onClose(Exception e)
  {
    scheduleReconnect();
  }

  @override
  void onError(Exception e)
  {
    _logger.warning(e.toString());
  }

  void scheduleReconnect()
  {
    if (_reconnectCount++ < _maxRetries) {
      Duration duration = new Duration(milliseconds: _reconnectIntervalMs);

      new Timer(duration, _channel.reconnect);
    }
  }
}

abstract class Callback
{
  void call(String methodName, {List args});
}

