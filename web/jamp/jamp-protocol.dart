part of jamp;

abstract class Message
{
  static final Map<String,String> EMPTY_MAP = new Map();

  Map<String,String> _headerMap;

  Message(Map<String,String> headerMap)
  {
    if (headerMap == null) {
      headerMap = EMPTY_MAP;
    }

    _headerMap = headerMap;
  }

  String serialize()
  {
    List list = new List();

    serializeImpl(list);

    String json = JSON.encode(list);

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
  String _toAddress;
  String _methodName;

  List _args;

  SendMessage(Map<String,String> headerMap,
              String toAddress,
              String methodName,
              [List args])
              : super(headerMap)
  {
    _toAddress = toAddress;
    _methodName = methodName;

    _args = args;
  }

  @override
  void serializeImpl(List list)
  {
    list.add("send");
    list.add(_headerMap);
    list.add(_toAddress);
    list.add(_methodName);

    List args = _args;

    if (args != null && args.length > 0) {
      for (var p in args) {
        list.add(p);
      }
    }
  }
}

class QueryMessage extends Message
{
  String _fromAddress;
  int _queryId;

  String _toAddress;
  String _methodName;

  List _args;

  QueryMessage(Map<String,String> headerMap,
               String fromAddress,
               int queryId,
               String toAddress,
               String methodName,
               [List args])
               : super(headerMap)
  {
    _fromAddress = fromAddress;
    _queryId = queryId;

    _toAddress = toAddress;
    _methodName = methodName;

    _args = args;
  }

  @override
  void serializeImpl(List list)
  {
    list.add("query");
    list.add(_headerMap);
    list.add(_fromAddress);
    list.add(_queryId);
    list.add(_toAddress);
    list.add(_methodName);

    List args = _args;

    if (args != null && args.length > 0) {
      for (var p in args) {
        list.add(p);
      }
    }
  }
}

class SubscribeMessage extends QueryMessage
{
  String _serviceName;
  String _myCallbackAddress;

  SubscribeMessage(Map<String,String> headerMap,
                   String fromAddress,
                   int queryId,
                   String serviceName,
                   String myCallbackAddress)
                   : super(headerMap,
                           fromAddress,
                           queryId,
                           "channel:",
                           "subscribe")
  {
    _serviceName = serviceName;
    _myCallbackAddress = myCallbackAddress;
  }

  @override
  void serializeImpl(List list)
  {
    list.add("query");
    list.add(_headerMap);
    list.add(_fromAddress);
    list.add(_queryId);
    list.add(_toAddress);
    list.add(_methodName);

    // args
    list.add(_serviceName);
    list.add(_myCallbackAddress);
  }
}

class ReplyMessage extends Message
{
  String _fromAddress;
  int _queryId;

  Object _result;

  Object get queryId => _queryId;
  Object get result => _result;

  ReplyMessage(Map<String,String> headerMap,
               String fromAddress,
               int queryId,
               Object result)
               : super(headerMap)
  {
    _fromAddress = fromAddress;
    _queryId = queryId;

    _result = result;
  }

  @override
  void serializeImpl(List list)
  {
    list.add("reply");
    list.add(_headerMap);
    list.add(_fromAddress);
    list.add(_queryId);
    list.add(_result);
  }
}

class ErrorMessage extends Message
{
  String _toAddress;
  int _queryId;

  Object _result;

  Object get queryId => _queryId;
  Object get result => _result;

  ErrorMessage(Map<String,String> headerMap,
               String toAddress,
               int queryId,
               Object result)
               : super(headerMap)
  {
    _toAddress = toAddress;
    _queryId = queryId;

    _result = result;
  }

  @override
  void serializeImpl(List list)
  {
    list.add("error");
    list.add(_headerMap);
    list.add(_toAddress);
    list.add(_queryId);
    list.add(_result);
  }
}

Message unserialize(String json)
{
  Object obj = JSON.decode(json);

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
