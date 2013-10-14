part of jamp;

typedef void ResponseCallback(Object result);

class WebSocketChannel extends BaseChannel
{
  Logger _logger = new Logger("JampWebSocketConnection");

  int queryId = 0;

  WebSocket _socket;

  bool _isClosing = false;

  List<Request> _requestQueue = new List<Request>();

  factory WebSocketChannel(String url)
  {
    if (url.startsWith("ws://") || url.startsWith("wss://")) {
    }
    else if (url.startsWith("http://")) {
      url = url.substring("http://".length);

      url = "ws://$url";
    }
    else if (url.startsWith("https://")) {
      url = url.substring("https://".length);

      url = "wss://$url";
    }
    else {
      url = "ws://$url";
    }

    return new WebSocketChannel._construct(url);
  }

  WebSocketChannel._construct(String url) : super._construct(url)
  {
    init();
  }

  void init()
  {
    if (_logger.isLoggable(Level.FINE)) {
      _logger.fine("initializing websocket connection to $this.uri");
    }

    if (_isClosing) {
      return;
    }

    WebSocket socket = new WebSocket(_url);
    _socket = socket;

    socket.onOpen.listen((Event event) {
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine("connection opened to $_url");
      }

      _manager.onOpen();

      submitRequestLoop();
    });

    socket.onClose.listen((CloseEvent event) {
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine("connection closed to $_url");
      }

      if (_isClosing) {
        return;
      }

      _manager.onClose(new Exception(event));
    });

    socket.onError.listen((Event event) {
      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine("socket error from $_url");
      }

      if (_isClosing) {
        return;
      }

      _manager.onError(new Exception(event));
    });

    socket.onMessage.listen((MessageEvent e) {
      String data = e.data;

      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine("received message from $_url: $data");
      }

      onMessageString(data);
    });
  }

  @override
  void close()
  {
    _isClosing = true;

    if (_socket.readyState == WebSocket.OPEN){
      _socket.close();
    }
  }

  @override
  void reconnect()
  {
    close();
    _isClosing = false;

    init();
  }

  @override
  void _submitRequest(Request request)
  {
    if (_isClosing) {
      throw new Exception("websocket is closing");
    }

    _requestQueue.add(request);

    if (_socket.readyState == WebSocket.OPEN) {
      submitRequestLoop();
    }
  }

  @override
  Request _removeRequest(int queryId)
  {
    super._removeRequest(queryId);

    for (int i = 0; i < _requestQueue.length; i++) {
      Request request = _requestQueue[i];

      if (request.queryId == queryId) {
        _requestQueue.remove(i);

        break;
      }
    }
  }

  void submitRequestLoop()
  {
    while (_socket.readyState == WebSocket.OPEN
           && _requestQueue.length > 0) {
      Request request = _requestQueue[0];
      String json = request.serialize();

      if (_logger.isLoggable(Level.FINE)) {
        _logger.fine("sending data to $this.uri: $json");
      }

      _socket.send(json);

      _requestQueue.removeAt(0);

      request.sent(this);
    }
  }
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
      String data = this.requestQueue[0];

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
