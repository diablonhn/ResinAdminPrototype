part of jamp;

typedef void ResponseCallback(Object result);

class JampWebSocketConnection
{
  Logger _logger = new Logger("JampWebSocketConnection");

  WebSocketConnection conn;
  Map<int,JampRequest> requestMap = new Map();

  int queryId = 0;

  JampWebSocketConnection(String uri)
  {
    this.conn = new WebSocketConnection(uri, onMessage);
  }

  void close()
  {
    this.conn.close();
  }

  void reconnect()
  {
    this.conn.reconnect();
  }

  void onMessage(String json)
  {
    try {
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine("received jamp message $json");
      }

      Message msg = unserialize(json);

      if (msg is ReplyMessage) {
        ReplyMessage reply = msg as ReplyMessage;

        int queryId = reply.queryId;
        JampRequest request = requestMap.remove(queryId);

        if (request == null) {
          throw new Exception("cannot find request for query id: $queryId");
        }

        request.completer.complete(reply);
      }
      else if (msg is ErrorMessage) {
        ErrorMessage reply = msg as ErrorMessage;

        int queryId = reply.queryId;
        JampRequest request = requestMap.remove(queryId);

        if (request == null) {
          throw new Exception("cannot find request for query id: $queryId");
        }

        print("nam0: $reply");

        request.completer.completeError(reply);
      }
      else {
        throw new Exception("unexpected jamp message type ($msg) for json: $json");
      }
    }
    catch (e, stackTrace) {
      print(e);
      print(stackTrace);
    }
  }

  Future<ReplyMessage> submitQuery(String serviceName,
                                    String methodName,
                                    {List parameters,
                                     String fromAddress : "me",
                                     Map<String,String> headerMap})
  {
    int queryId = this.queryId++;

    QueryMessage query = new QueryMessage(headerMap,
                                          fromAddress,
                                          queryId,
                                          serviceName,
                                          methodName,
                                          parameters);

    JampRequest request = new JampRequest(query);
    this.requestMap[queryId] = request;

    submitMessage(query);

    return request.getFuture();
  }

  void submitMessage(Message msg)
  {
    String json = msg.serialize();

    this.conn.addRequest(json);
  }

  /**
   * Runs periodically to prune requests that have timed out, and invoking
   * error callbacks if applicable.
   */
  void checkRequests()
  {
    this.requestMap.forEach((int queryId, JampRequest request) {
      if (request.isExpired()) {
        this.requestMap.remove(queryId);

        request.completer.completeError("expired request");
      }
    });
  }
}

class JampRequest<T>
{
  QueryMessage query;
  DateTime expirationTime;

  Completer<T> completer;

  JampRequest(QueryMessage query,
              {Duration timeout : const Duration(seconds : 5)})
  {
    this.query = query;

    this.expirationTime = new DateTime.now().add(timeout);

    this.completer = new Completer<T>();
  }

  bool isExpired([DateTime now])
  {
    if (now == null) {
      now = new DateTime.now();
    }

    return now.isAfter(this.expirationTime);
  }

  int getQueryId() => this.query.queryId;

  Future<T> getFuture() => this.completer.future;
}

class WebSocketConnection
{
  Logger _logger = new Logger("WebSocketConnection");

  WebSocket socket;

  String uri;

  bool isReconnectOnClose;
  bool isReconnectOnError;
  int reconnectIntervalMs;

  bool isClosing = false;

  var onMessageHandler;

  List<String> requestQueue = new List<String>();

  WebSocketConnection(String this.uri,
                      this.onMessageHandler,
                      {bool this.isReconnectOnClose : true,
                      bool this.isReconnectOnError : true,
                      int this.reconnectIntervalMs : 5000})
  {
    init();
  }

  void init()
  {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine("initializing websocket connection to $this.uri");
    }

    if (this.isClosing) {
      return;
    }

    WebSocket socket = new WebSocket(uri);
    this.socket = socket;

    socket.onOpen.listen(onOpen);
    socket.onClose.listen(onClose);
    socket.onError.listen(onError);

    socket.onMessage.listen(onMessage);
  }

  void addRequest(String data)
  {
    if (this.isClosing) {
      throw new Exception("websocket is closing");
    }

    this.requestQueue.add(data);

    if (this.socket.readyState == WebSocket.OPEN) {
      submitRequestLoop();
    }
  }

  void submitRequestLoop()
  {
    while (this.socket.readyState == WebSocket.OPEN
           && this.requestQueue.length > 0) {
      String data = this.requestQueue.elementAt(0);

      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine("sending data to $this.uri: $data");
      }

      this.socket.send(data);

      this.requestQueue.removeAt(0);
    }
  }

  void onOpen(Event e)
  {
    submitRequestLoop();
  }

  void onMessage(MessageEvent e)
  {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine("received message from $this->uri: " + e.data);
    }

    this.onMessageHandler(e.data);
  }

  void onClose(CloseEvent e)
  {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine("connection closed from $this->uri");
    }

    if (this.isClosing) {
      return;
    }

    if (this.isReconnectOnClose) {
      reconnect();
    }
  }

  void onError(Event e)
  {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine("socket error from $this->uri");
    }

    if (this.isClosing) {
      return;
    }

    if (this.isReconnectOnError){
      reconnect();
    }
  }

  void reconnect()
  {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine("scheduling reconnect for $this->uri");
    }

    close();
    this.isClosing = false;

    new Timer(new Duration(milliseconds: this.reconnectIntervalMs), init);
  }

  void close()
  {
    this.isClosing = true;

    if (this.socket.readyState == WebSocket.OPEN){
      this.socket.close();
    }
  }
}
