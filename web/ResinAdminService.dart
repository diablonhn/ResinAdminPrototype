library ResinAdminService;

import "package:meta/meta.dart" show override;

import 'dart:async';
import 'dart:collection';

import 'jamp/jamp.dart' as Jamp;

class ResinAdminService
{
  static const String SERVICE_NAME = "/admin";

  Jamp.JampWebSocketConnection conn;

  ResinAdminService(this.conn);

  Future<String> getCurrentServerId()
  {
    String methodName = "getCurrentServerId";

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName);

    Completer<String> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      String result = msg.result as String;

      completer.complete(result);
    });

    return completer.future;
  }

  Future<ServerInfo> getServerInfo([String serverId])
  {
    String methodName = "getServerInfo";

    List args = [serverId];

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<ServerInfo> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      Map result = msg.result as Map;

      ServerInfo serverInfo = new ServerInfo.fromMap(result);

      completer.complete(serverInfo);
    });

    return completer.future;
  }

  Future<List<String>> getServers()
  {
    String methodName = "getServers";

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName);

    Completer<List<String>> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      List<String> result = msg.result as List;

      completer.complete(result);
    });

    return completer.future;
  }

  Future<HealthStatus> getHealthStatus([String serverId])
  {
    String methodName = "getHealthStatus";

    List<String> args = null;

    if (serverId != null) {
      args = [serverId];
    }

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<HealthStatus> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      Map<String,String> result = msg.result as Map;

      HealthStatus status = new HealthStatus.fromMap(result);

      completer.complete(status);
    });

    return completer.future;
  }

  Future<List<HealthCheck>> getHealthChecks([String serverId])
  {
    String methodName = "getHealthChecks";

    List<String> args = null;

    if (serverId != null) {
      args = [serverId];
    }

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<List<HealthCheck>> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      List<Map<String,Object>> result = msg.result as List;

      List<HealthCheck> checkList = new List();
      HealthCheck overallCheck = null;

      for (Map<String,Object> map in result) {
        HealthCheck check = new HealthCheck.fromMap(map);

        if (check.name == "Resin") {
          overallCheck = check;
        }
        else {
          checkList.add(check);
        }
      }

      if (overallCheck == null) {
        throw new Exception("Resin overall health check not found");
      }

      checkList.sort();
      checkList.insert(0, overallCheck);

      completer.complete(checkList);
    });

    return completer.future;
  }

  Future<List<HealthLog>> getHealthLogs(String serverId,
                                        int startTime,
                                        [int endTime = -1,
                                         int limit = 100])
  {
    String methodName = "getHealthLogs";

    List<String> args = null;

    args = [serverId, startTime, endTime, limit];

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<List<HealthLog>> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      List<Map<String,Object>> result = msg.result as List;

      List<HealthLog> logList = new List();

      for (Map<String,Object> map in result) {
        HealthLog log = new HealthLog.fromMap(map);

        logList.add(log);
      }

      completer.complete(logList);
    });

    return completer.future;
  }

  Future<MemoryState> getMemoryState([String serverId])
  {
    String methodName = "getMemoryState";

    List<String> args = null;

    if (serverId != null) {
      args = [serverId];
    }

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<MemoryState> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      Map result = msg.result as Map;

      MemoryState state = new MemoryState.fromMap(result);

      completer.complete(state);
    });

    return completer.future;
  }

  Future<ThreadingInfo> getThreadingInfo([String serverId])
  {
    String methodName = "getThreadingInfo";

    List<String> args = null;

    if (serverId != null) {
      args = [serverId];
    }

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<ThreadingInfo> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      Map result = msg.result as Map;

      ThreadingInfo info = new ThreadingInfo.fromMap(result);

      completer.complete(info);
    });

    return completer.future;
  }

  Future<ThreadScoreboard> getThreadScoreboard([String serverId])
  {
    String methodName = "getThreadScoreboard";

    List<String> args = null;

    if (serverId != null) {
      args = [serverId];
    }

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<ThreadScoreboard> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      Map result = msg.result as Map;

      ThreadScoreboard board = new ThreadScoreboard.fromMap(result);

      completer.complete(board);
    });

    return completer.future;
  }

  Future<List<ThreadDump>> getThreadDumps([String serverId]) {
    String methodName = "getThreadDumps";

    List<String> args = null;

    args = [serverId];

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<List<ThreadDump>> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      List<Map<String,Object>> result = msg.result as List;

      List<ThreadDump> dumpList = new List();

      for (Map<String,Object> map in result) {
        ThreadDump threadDump = new ThreadDump.fromMap(map);

        dumpList.add(threadDump);
      }

      completer.complete(dumpList);
    });

    return completer.future;
  }

  Future<List<MBean>> jmxQuery(String query)
  {
    String methodName = "jmxQueryMBeans";

    List<String> args = [query];

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<List<MBean>> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      List<Map<String,Object>> result = msg.result as List;

      List<MBean> mbeanList = new List();

      for (Map<String,Object> map in result) {
        MBean mbean = new MBean.fromMap(map);

        if (mbean.name.startsWith("JMImplementation")) {
          continue;
        }

        mbeanList.add(mbean);
      }

      completer.complete(mbeanList);
    });

    return completer.future;
  }
}

class HealthStatus
{
  String serverId;

  String status;
  String message;

  HealthStatus(this.serverId, this.status, this.message);

  HealthStatus.fromMap(Map<String,String> map) : this(map["_serverId"],
                                                      map["_status"],
                                                      map["_message"]);
}

class HealthCheck implements Comparable
{
  String serverId;

  String name;
  String status;
  String message;

  HealthCheck(this.serverId, this.name, this.status, this.message);

  HealthCheck.fromMap(Map<String,Object> map) : this(map["_serverId"],
                                                     map["_name"],
                                                     map["_status"],
                                                     map["_message"]);

  int compareTo(HealthCheck check1)
  {
    return this.name.compareTo(check1.name);
  }
}

class HealthLog
{
  String serverId;

  HealthLogType type;
  int timestampMs;

  String source;
  String message;

  HealthLog(this.serverId, this.type, this.timestampMs, this.source, this.message);

  HealthLog.fromMap(Map<String,Object> map) : this(map["_serverId"],
                                                   new HealthLogType.fromString(map["_type"]),
                                                   map["_timestamp"],
                                                   map["_source"],
                                                   map["_message"]);
}

class HealthLogType
{
  static const HealthLogType START_MESSAGE
    = const HealthLogType("START_MESSAGE", "Startup Message");

  static const HealthLogType START_TIME
    = const HealthLogType("START_TIME", "Server Startup");

  static const HealthLogType CHECK
    = const HealthLogType("CHECK", "Health Alarm");

  static const HealthLogType RECHECK
    = const HealthLogType("RECHECK", "Recheck");

  static const HealthLogType RECOVER
    = const HealthLogType("RECOVER", "Health Recovery");

  static const HealthLogType ACTION
    = const HealthLogType("ACTION", "Health Action");

  static const HealthLogType ANOMALY
    = const HealthLogType("ANOMALY", "Anomaly Detected");

  final String name;
  final String description;

  const HealthLogType(String this.name, String this.description);

  factory HealthLogType.fromString(String name)
  {
    switch (name) {
      case "START_MESSAGE": return START_MESSAGE;
      case "START_TIME":    return START_TIME;
      case "CHECK":         return CHECK;
      case "RECHECK":       return RECHECK;
      case "RECOVER":       return RECOVER;
      case "ACTION":        return ACTION;
      case "ANOMALY":       return ANOMALY;
      default:
        throw new Exception("unknown log type: name");
    }
  }
}

class ServerInfo
{
  String serverId;
  int serverIndex;

  String user;
  String machine;

  String resinVersion;
  String jdkVersion;

  String osVersion;
  String license;

  String watchdogMessage;
  String state;

  int startTime;
  int uptime;

  int freeHeap;
  int totalHeap;

  int fileDescriptors;
  int maxFileDescriptors;

  int freeSwap;
  int totalSwap;

  int freePhysical;
  int totalPhysical;

  double cpuLoadAverage;

  ServerInfo(this.serverId,
             this.serverIndex,
             this.user,
             this.machine,
             this.resinVersion,
             this.jdkVersion,
             this.osVersion,
             this.license,
             this.watchdogMessage,
             this.state,
             this.startTime,
             this.uptime,
             this.freeHeap,
             this.totalHeap,
             this.fileDescriptors,
             this.maxFileDescriptors,
             this.freeSwap,
             this.totalSwap,
             this.freePhysical,
             this.totalPhysical,
             this.cpuLoadAverage);

  ServerInfo.fromMap(Map map) : this(map["_serverId"],
                                     map["_serverIndex"],
                                     map["_user"],
                                     map["_machine"],
                                     map["_resinVersion"],
                                     map["_jdkVersion"],
                                     map["_osVersion"],
                                     map["_license"],
                                     map["_watchdogMessage"],
                                     map["_state"],
                                     map["_startTime"],
                                     map["_uptime"],
                                     map["_freeHeap"],
                                     map["_totalHeap"],
                                     map["_fileDescriptors"],
                                     map["_maxFileDescriptors"],
                                     map["_freeSwap"],
                                     map["_totalSwap"],
                                     map["_freePhysical"],
                                     map["_totalPhysical"],
                                     map["_cpuLoadAverage"]);
}

class MemoryState
{
  String serverId;

  int codeCacheCommitted;
  int codeCacheMax;
  int codeCacheUsed;
  int codeCacheFree;

  int edenCommitted;
  int edenMax;
  int edenUsed;
  int edenFree;

  int permGenCommitted;
  int permGenMax;
  int permGenUsed;
  int permGenFree;

  int survivorCommitted;
  int survivorMax;
  int survivorUsed;
  int survivorFree;

  int tenuredCommitted;
  int tenuredMax;
  int tenuredUsed;
  int tenuredFree;

  int garbageCollectionTime;
  int garbageCollectionCount;

  MemoryState(this.serverId,
              this.codeCacheCommitted, this.codeCacheMax,
              this.codeCacheUsed, this.codeCacheFree,
              this.edenCommitted, this.edenMax,
              this.edenUsed, this.edenFree,
              this.permGenCommitted, this.permGenMax,
              this.permGenUsed, this.permGenFree,
              this.survivorCommitted, this.survivorMax,
              this.survivorUsed, this.survivorFree,
              this.tenuredCommitted, this.tenuredMax,
              this.tenuredUsed, this.tenuredFree,
              this.garbageCollectionTime, this.garbageCollectionCount);

  MemoryState.fromMap(Map map) : this(map["_serverId"],
                                      map["_codeCacheCommitted"], map["_codeCacheMax"],
                                      map["_codeCacheUsed"], map["_codeCacheFree"],
                                      map["_edenCommitted"], map["_edenMax"],
                                      map["_edenUsed"], map["_edenFree"],
                                      map["_permGenCommitted"], map["_permGenMax"],
                                      map["_permGenUsed"], map["_permGenFree"],
                                      map["_survivorCommitted"], map["_survivorMax"],
                                      map["_survivorUsed"], map["_survivorFree"],
                                      map["_tenuredCommitted"], map["_tenuredMax"],
                                      map["_tenuredUsed"], map["_tenuredFree"],
                                      map["_garbageCollectionTime"], map["_garbageCollectionCount"]);
}

class MBean implements Comparable
{
  String name;
  String type;

  LinkedHashMap<String,Object> valueMap;

  MBean(String name, Map<String,Object> map)
  {
    this.name = name;

    int p = name.indexOf("type=");

    if (p >= 0) {
      int end = name.indexOf(",", p + 5);

      if (end < 0 || end > name.length) {
        end = name.length;
      }

      this.type = name.substring(p + 5, end);
    }

    List<String> keyList = new List.from(map.keys);
    keyList.sort();

    this.valueMap = new LinkedHashMap();

    for (String key in keyList) {
      this.valueMap[key] = map[key];
    }
  }

  MBean.fromMap(Map<String,Object> map) : this(map["ObjectName"],
                                               map);

  @override
  int compareTo(MBean bean)
  {
    return this.type.compareTo(bean.type);
  }

  @override
  String toString()
  {
    return "MBean[$name]";
  }
}

class ThreadingInfo
{
  String serverId;

  int activeResinThreads;
  int idleResinThreads;
  int totalResinThreads;

  int runnableJvmThreads;
  int nativeJvmThreads;
  int blockedJvmThreads;
  int waitingJvmThreads;
  int totalJvmThreads;
  int peakJvmThreads;

  ThreadingInfo(this.serverId,
                this.activeResinThreads,
                this.idleResinThreads,
                this.totalResinThreads,
                this.runnableJvmThreads,
                this.nativeJvmThreads,
                this.blockedJvmThreads,
                this.waitingJvmThreads,
                this.totalJvmThreads,
                this.peakJvmThreads);

  ThreadingInfo.fromMap(Map map) : this(map["_serverId"],
                                        map["_activeResinThreads"],
                                        map["_idleResinThreads"],
                                        map["_totalResinThreads"],
                                        map["_runnableJvmThreads"],
                                        map["_nativeJvmThreads"],
                                        map["_blockedJvmThreads"],
                                        map["_waitingJvmThreads"],
                                        map["_totalJvmThreads"],
                                        map["_peakJvmThreads"]);
}

class ThreadScoreboard
{
  Map<String,String> scoreboardMap;
  Map<String,String> keyMap;

  ThreadScoreboard(this.scoreboardMap, this.keyMap);

  ThreadScoreboard.fromMap(Map map) : this(map["_scoreboardMap"],
                                           map["_keyMap"]);
}

class ThreadDump implements Comparable
{
  int id;
  String name;

  String state;
  bool isNative;
  String stackTrace;

  bool isIdlePoolThread;
  bool isKeepAliveThread;

  String appClassName;
  String appMethodName;

  String url;

  ThreadDump(this.id, this.name, this.state, this.isNative, this.stackTrace,
             this.isIdlePoolThread, this.isKeepAliveThread,
             this.appClassName, this.appMethodName, this.url);

  ThreadDump.fromMap(Map map) : this(map["_id"],
                                     map["_name"],
                                     map["_state"],
                                     map["_isNative"],
                                     map["_stackTrace"],
                                     map["_isIdlePoolThread"],
                                     map["_isKeepAliveThread"],
                                     map["_appClassName"],
                                     map["_appMethodName"],
                                     map["_url"]);

  int compareTo(ThreadDump dump)
  {
    int result = this.name.compareTo(dump.name);

    if (result != 0) {
      return result;
    }
    else {
      return this.id.compareTo(dump.id);
    }
  }
}
