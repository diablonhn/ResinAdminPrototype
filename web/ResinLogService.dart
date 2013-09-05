library ResinLogService;

import "package:meta/meta.dart" show override;

import 'dart:async';
import 'jamp/jamp.dart' as Jamp;

class ResinLogService
{
  static const String SERVICE_NAME = "/log";

  Jamp.JampWebSocketConnection conn;

  ResinLogService(this.conn);

  Future<List<LogMessage>> getLog(String serverId,
                                  Level level,
                                  int startTimeMs,
                                  [int endTime = -1])
  {
    String methodName = "getLog";

    List args = [serverId, level.name, startTimeMs, endTime];

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<List<LogMessage>> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      List<Map> result = msg.result as List;

      List<LogMessage> logList = new List();

      for (Map map in result) {
        LogMessage log = new LogMessage.fromMap(map);

        logList.add(log);
      }

      completer.complete(logList);
    });

    return completer.future;
  }
}

class LogMessage
{
  String type;
  String name;

  String server;
  String thread;

  int timestampMs;

  Level level;
  String message;

  LogMessage(this.type,
             this.name,
             this.server,
             this.thread,
             this.timestampMs,
             this.level,
             this.message);

  LogMessage.fromMap(Map map) : this(map["_type"],
                                     map["_name"],
                                     map["_server"],
                                     map["_thread"],
                                     map["_timestamp"],
                                     new Level.fromName(map["_level"]),
                                     map["_message"]);

  @override
  String toString()
  {
    return "Log[$level, $timestampMs, $message, $name, $type, $server, $thread]";
  }
}

class Level
{
  static const Level ALL = const Level("all");
  static const Level FINEST = const Level("finest");
  static const Level FINER = const Level("finer");
  static const Level FINE = const Level("fine");
  static const Level CONFIG = const Level("config");
  static const Level INFO = const Level("info");
  static const Level WARNING = const Level("warning");

  final String name;

  const Level(String this.name);

  factory Level.fromName(String name)
  {
    name = name.toLowerCase();

    if (name == "all") {
      return ALL;
    }
    else if (name == "finest") {
      return FINEST;
    }
    else if (name == "finer") {
      return FINER;
    }
    else if (name == "fine") {
      return FINE;
    }
    else if (name == "config") {
      return CONFIG;
    }
    else if (name == "info") {
      return INFO;
    }
    else if (name == "warning") {
      return WARNING;
    }
    else {
      throw new Exception("unknown level: $name");
    }
  }

  static List<Level> getLevelList()
  {
    return [ALL, FINEST, FINER, FINE, CONFIG, INFO, WARNING];
  }

  @override
  String toString()
  {
    return "Level[$name]";
  }
}