part of jamp;

class HttpChannel extends BaseChannel
{
  Timer pollTimer;
  PollStrategy pollStrategy;

  factory HttpChannel(String url)
  {
    if (url.startsWith("http://") || url.startsWith("https://")) {
    }
    else if (url.startsWith("ws://")) {
      url = url.substring("ws://".length);

      url = "http://$url";
    }
    else if (url.startsWith("wss://")) {
      url = url.substring("wss://".length);

      url = "https://$url";
    }
    else {
      url = "http://$url";
    }

    return new HttpChannel._construct(url);
  }

  HttpChannel._construct(String url) : super._construct(url)
  {
    this.pollStrategy = new ConstantPollStrategy(const Duration(milliseconds : 2000));
  }

  void setPollStrategy(PollStrategy strategy)
  {
    this.pollStrategy = pollStrategy;
  }

  @override
  void close()
  {
    this.pollTimer.cancel();
  }

  @override
  void reconnect()
  {
    schedulePoll();
  }

  @override
  void _submitRequest(Request request)
  {
    bool isBlocking = _isBlocking;

    Message msg = request.msg;

    HttpRequest httpRequest;
    String data;

    if (isBlocking) {
      data = msg.serialize();

      httpRequest = initRpcRequest();
    }
    else {
      data = "[" + msg.serialize() + "]";

      httpRequest = initPushRequest();
    }

    httpRequest.send(data);

    httpRequest.onLoadEnd.listen((ProgressEvent event) {
      if (httpRequest.status == 200) {
        request.sent(this);

        if (isBlocking) {
          String json = httpRequest.responseText;

          Message msg = unserialize(json);

          onMessage(msg);
        }
        else {
          schedulePoll();
        }
      }
      else {
        request.error(this, "error submitting query data: "
                            + "${httpRequest.statusText}, "
                            + "${httpRequest.responseText}");
      }
    });
  }

  HttpRequest initPullRequest()
  {
    HttpRequest request = new HttpRequest();

    request.open("GET", _url);

    request.setRequestHeader("Content-Type", "x-application/jamp-poll");

    return request;
  }

  HttpRequest initPushRequest()
  {
    HttpRequest request = new HttpRequest();

    request.open("POST", _url);

    request.setRequestHeader("Content-Type", "x-application/jamp-push");

    return request;
  }

  HttpRequest initRpcRequest()
  {
    HttpRequest request = new HttpRequest();

    request.open("POST", _url);

    request.setRequestHeader("Content-Type", "x-application/jamp-rpc");

    return request;
  }

  void pull()
  {
    HttpRequest httpRequest = initPullRequest();
    httpRequest.send();

    httpRequest.onLoadEnd.listen((ProgressEvent event) {
      if (httpRequest.status == 200) {
        String json = httpRequest.responseText;

        List list = JSON.decode(json);

        for (List item in list) {
          Message msg = unserializeList(item);

          onMessage(msg);
        }
      }

      schedulePoll();
    });
  }

  void schedulePoll()
  {
    if (_requestMap.length == 0 && _callbackMap.length == 0) {
      return;
    }
    else if (this.pollTimer != null && this.pollTimer.isActive) {
      return;
    }

    Duration duration = this.pollStrategy.getUpdateInterval();

    if (duration != null) {
      if (this.pollTimer != null) {
        this.pollTimer.cancel();
      }

      this.pollTimer = new Timer(duration, pull);
    }
  }
}

abstract class PollStrategy
{
  Duration getUpdateInterval();
}

class ConstantPollStrategy extends PollStrategy
{
  Duration pollInterval;

  ConstantPollStrategy(Duration this.pollInterval);

  @override
  Duration getUpdateInterval()
  {
    return this.pollInterval;
  }
}
