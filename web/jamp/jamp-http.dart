part of jamp;

class JampHttpChannel
{
  String url;

  int queryId = 0;

  Map<int,JampRequest> requestMap = new Map();
  Map<int,JampRequest> activeRequestMap = new Map();

  Timer pollTimer;
  PollStrategy pollStrategy;

  JampHttpChannel(String url,
                  {PollStrategy pollStrategy})
  {
    this.url = url;

    if (pollStrategy == null) {
      pollStrategy = new ConstantPollStrategy(const Duration(milliseconds : 2000));
    }

    this.pollStrategy = pollStrategy;
  }

  HttpRequest initPullRequest()
  {
    HttpRequest request = new HttpRequest();

    request.open("GET", url);

    request.setRequestHeader("Content-Type", "x-application/jamp-poll");

    return request;
  }

  HttpRequest initPushRequest()
  {
    HttpRequest request = new HttpRequest();

    request.open("POST", url);

    request.setRequestHeader("Content-Type", "x-application/jamp-push");

    return request;
  }

  HttpRequest initRpcRequest()
  {
    HttpRequest request = new HttpRequest();

    request.open("POST", url);

    request.setRequestHeader("Content-Type", "x-application/jamp-rpc");

    return request;
  }

  Future<ReplyMessage> submitQuery(String serviceName,
                                   String methodName,
                                   {List parameters,
                                    String fromAddress : "me",
                                    Map<String,String> headerMap,
                                    bool isBlocking : true})
  {
    int queryId = this.queryId++;

    QueryMessage query = new QueryMessage(headerMap,
                                          fromAddress,
                                          queryId,
                                          serviceName,
                                          methodName,
                                          parameters);

    JampRequest<ReplyMessage> request = new JampRequest(query);

    this.requestMap[queryId] = request;

    submitQueryMessage(request, isBlocking);

    return request.getFuture();
  }

  void submitQueryMessage(JampRequest<ReplyMessage> request, bool isBlocking)
  {
    print("jamp-http0");

    QueryMessage msg = request.query;

    String json = msg.serialize();

    json = "[$json]";

    HttpRequest httpRequest;

    if (isBlocking) {
      httpRequest = initPushRequest();
    }
    else {
      httpRequest = initRpcRequest();
    }

    print("jamp-http1");

    httpRequest.send(json);

    httpRequest.onLoadEnd.listen((ProgressEvent event) {
      print("jamp-http2: ${httpRequest.status} ${httpRequest.responseText}");

      if (httpRequest.status == 200) {
        this.activeRequestMap[request.getQueryId()] = request;

        Duration newInterval
          = this.pollStrategy.submittedMessages(1, this.activeRequestMap.length);

        schedulePollTimer(newInterval);
      }
      else {
        this.requestMap.remove(request.getQueryId());

        request.completer.completeError("error submiting query $json: "
                                        + "${httpRequest.statusText}, "
                                        + "${httpRequest.responseText}");
      }
    });
  }

  void pull()
  {
    if (this.activeRequestMap.length == 0) {
      return;
    }

    HttpRequest httpRequest = initPullRequest();
    httpRequest.send();

    httpRequest.onLoadEnd.listen((ProgressEvent event) {
      int completedCount = 0;

      if (httpRequest.status == 200) {
        String json = httpRequest.responseText;

        List list = JSON.parse(json);

        for (List item in list) {
          Message message = unserializeList(item);

          if (message is ReplyMessage) {
            completedCount++;

            ReplyMessage reply = message as ReplyMessage;

            int queryId = reply.queryId;
            JampRequest request = removeRequest(queryId);

            if (request != null) {
              request.completer.complete(reply);
            }
          }
          else if (message is ErrorMessage) {
            completedCount++;

            ErrorMessage error = message as ErrorMessage;

            int queryId = error.queryId;
            JampRequest request = removeRequest(queryId);

            if (request != null) {
              request.completer.completeError(error);
            }
          }
          else {
            throw new Exception("unknown message type: $message");
          }
        }
      }

      DateTime now = new DateTime.now();

      for (JampRequest request in this.activeRequestMap.values) {
        if (request.isExpired(now)) {
          completedCount++;

          removeRequest(request.query.queryId);

          request.completer.completeError("request has timed out");
        }
      }

      Duration newInterval
        = this.pollStrategy.receivedMessages(completedCount,
                                             this.activeRequestMap.length);

      schedulePollTimer(newInterval);
    });
  }

  void schedulePollTimer(Duration duration)
  {
    print("schedulePollTimer0: $duration $pollTimer ${activeRequestMap.length}");

    if (duration != null) {
      if (this.pollTimer != null) {
        this.pollTimer.cancel();
      }

      this.pollTimer = new Timer(duration, pull);
    }
  }

  JampRequest removeRequest(int queryId)
  {
    this.activeRequestMap.remove(queryId);

    return this.requestMap.remove(queryId);
  }
}

abstract class PollStrategy
{
  Duration submittedMessages(int count, int totalOutstanding);

  Duration receivedMessages(int count, int outstandingRemaining);
}

class ConstantPollStrategy extends PollStrategy
{
  Duration pollInterval;
  Duration previousInterval;

  ConstantPollStrategy(Duration this.pollInterval);

  @override
  Duration submittedMessages(int count, int totalOutstanding)
  {
    if (this.previousInterval == null) {
      this.previousInterval = this.pollInterval;

      return this.pollInterval;
    }
    else {
      return null;
    }
  }

  @override
  Duration receivedMessages(int count, int outstandingRemaining)
  {
    if (outstandingRemaining > 0) {
      this.previousInterval = this.pollInterval;

      return this.pollInterval;
    }
    else {
      this.previousInterval = null;

      return null;
    }
  }
}
