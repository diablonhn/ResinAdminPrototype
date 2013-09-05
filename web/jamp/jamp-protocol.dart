part of jamp;

abstract class Message
{
  static final Map<String,String> EMPTY_MAP = new Map();

  Map<String,String> headerMap;

  Message(Map<String,String> headerMap)
  {
    if (headerMap == null) {
      headerMap = EMPTY_MAP;
    }

    this.headerMap = headerMap;
  }

  String serialize()
  {
    List list = new List();

    serializeImpl(list);

    String json = JSON.stringify(list);

    return json;
  }

  void serializeImpl(List list);

  @override
  String toString()
  {
    return runtimeType.toString() + "[" + serialize() + "]";
  }
}

class SendMessage extends Message
{
  String toAddress;
  String methodName;

  List parameters;

  SendMessage(Map<String,String> headerMap,
              String toAddress,
              String methodName,
              [List parameters])
              : super(headerMap)
  {
    this.methodName = methodName;

    this.parameters = parameters;
  }

  @override
  void serializeImpl(List list)
  {
    list.add("send");
    list.add(this.headerMap);
    list.add(this.toAddress);
    list.add(this.methodName);

    List parameters = this.parameters;

    if (parameters != null && parameters.length > 0) {
      for (var p in parameters) {
        list.add(p);
      }
    }
  }
}

class QueryMessage extends Message
{
  String fromAddress;
  int queryId;

  String toAddress;
  String methodName;

  List parameters;

  QueryMessage(Map<String,String> headerMap,
               String fromAddress,
               int queryId,
               String toAddress,
               String methodName,
               [List parameters])
               : super(headerMap)
  {
    this.fromAddress = fromAddress;
    this.queryId = queryId;

    this.toAddress = toAddress;
    this.methodName = methodName;

    this.parameters = parameters;
  }

  @override
  void serializeImpl(List list)
  {
    list.add("query");
    list.add(this.headerMap);
    list.add(this.fromAddress);
    list.add(this.queryId);
    list.add(this.toAddress);
    list.add(this.methodName);

    List parameters = this.parameters;

    if (parameters != null && parameters.length > 0) {
      for (var p in parameters) {
        list.add(p);
      }
    }
  }
}

class ReplyMessage extends Message
{
  String fromAddress;
  int queryId;
  String methodName;

  Object result;

  ReplyMessage(Map<String,String> headerMap,
               String fromAddress,
               int queryId,
               Object result)
               : super(headerMap)
  {
    this.fromAddress = fromAddress;
    this.queryId = queryId;
    this.methodName = methodName;

    this.result = result;
  }

  @override
  void serializeImpl(List list)
  {
    list.add("reply");
    list.add(this.headerMap);
    list.add(this.fromAddress);
    list.add(this.queryId);
    list.add(this.result);
  }
}

class ErrorMessage extends Message
{
  String toAddress;
  int queryId;

  Object result;

  ErrorMessage(Map<String,String> headerMap,
               String toAddress,
               int queryId,
               Object result)
               : super(headerMap)
  {
    this.toAddress = toAddress;
    this.queryId = queryId;

    this.result = result;
  }

  @override
  void serializeImpl(List list)
  {
    list.add("error");
    list.add(this.headerMap);
    list.add(this.toAddress);
    list.add(this.queryId);
    list.add(this.result);
  }
}

Message unserialize(String json)
{
  Object obj = JSON.parse(json);

  if (obj is List) {
    return unserializeList(obj as List);
  }
}

Message unserializeList(List list)
{
  String type = list[0];

  switch (type) {
    case "reply":
      if (list.length < 5) {
        throw new Exception("incomplete message for JAMP type: " + type);
      }

      Map<String,String> headerMap = list[1];
      String fromAddress = list[2];
      int queryId = list[3];
      Object result = list[4];

      return new ReplyMessage(headerMap, fromAddress, queryId, result);

    case "error":
      if (list.length < 5) {
        throw new Exception("incomplete message for JAMP type: " + type);
      }

      Map<String,String> headerMap = list[1];
      String toAddress = list[2];
      int queryId = list[3];
      Object result = list[4];

      return new ErrorMessage(headerMap, toAddress, queryId, result);

      break;
    default:
  }
}
