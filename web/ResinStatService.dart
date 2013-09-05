library ResinStatService;

import "package:meta/meta.dart" show override;

import 'dart:async';
import 'jamp/jamp.dart' as Jamp;

class ResinStatService
{
  static const String SERVICE_NAME = "/stat";

  Jamp.JampWebSocketConnection conn;

  ResinStatService(this.conn);

  Future<List<String>> getNames()
  {
    String methodName = "getNames";

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName);

    Completer<List<String>> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      List<String> result = msg.result as List;

      completer.complete(result);
    });

    return completer.future;
  }

  Future<List<StatValue>> getData(String serverId,
                                  String name,
                                  [int beginTime = -1,
                                   int endTime = -1,
                                   int stepTime = -1])
  {
    String methodName = "getData";

    if (beginTime < 0) {
      DateTime date = new DateTime.now().subtract(const Duration(hours : 1));

      beginTime = date.millisecondsSinceEpoch;
    }

    if (endTime < 0 && beginTime > 0) {
      endTime = beginTime + 1000 * 60 * 60;
    }

    if (stepTime < 0) {
      stepTime = (endTime - beginTime) ~/ 1000;

      if (stepTime == 0) {
        stepTime = 1;
      }
    }

    List args = [serverId, name, beginTime, endTime, stepTime];

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<List<StatValue>> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      List<Map> result = msg.result as List;

      List<StatValue> list = new List();

      for (Map map in result) {
        StatValue value = new StatValue.fromMap(map);

        list.add(value);
      }

      completer.complete(list);
    });

    return completer.future;
  }

  Future<List<DownTime>> getDownTimes(String serverId,
                                      int start,
                                      [int end = -1])
  {
    String methodName = "getDownTimes";

    List args = [serverId, start, end];

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<List<DownTime>> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      List<Map> result = msg.result as List;

      List<DownTime> list = new List();

      for (Map map in result) {
        DownTime downTime = new DownTime.fromMap(map);

        list.add(downTime);
      }

      completer.complete(list);
    });

    return completer.future;
  }

  Future<List<int>> getStartTimes(String serverId, int startTime, int endTime)
  {
    String methodName = "getStartTimes";

    List args = [serverId, startTime, endTime];

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<List<int>> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      List<int> result = msg.result as List;

      completer.complete(result);
    });

    return completer.future;
  }

  Future<List<MeterGraphPage>> getMeterGraphPages([String serverId])
  {
    String methodName = "getMeterGraphPages";

    List args = [serverId];

    Future<Jamp.ReplyMessage> future
      = this.conn.submitQuery(SERVICE_NAME, methodName, parameters : args);

    Completer<List<MeterGraphPage>> completer = new Completer();

    future.then((Jamp.ReplyMessage msg) {
      List<Map> result = msg.result as List;

      List<MeterGraphPage> list = new List();

      for (Map map in result) {
        MeterGraphPage page = new MeterGraphPage.fromMap(map);

        list.add(page);
      }

      completer.complete(list);
    });

    return completer.future;
  }
}

class StatValue
{
  int time;
  int count;
  double sum;
  double min;
  double max;

  StatValue(this.time, this.count, this.sum, this.min, this.max);

  StatValue.fromMap(Map map) : this(map["_time"],
                                    map["_count"],
                                    map["_sum"],
                                    map["_min"],
                                    map["_max"]);

  String toString()
  {
    return "StatValue[$time,$max]";
  }
}

class DownTime
{
  int startTime;
  int endTime;

  bool estimated;
  bool dataAbsent;

  DownTime(this.startTime, this.endTime, this.estimated, this.dataAbsent);

  DownTime.fromMap(Map map) : this(map["_startTime"],
                                   map["_endTime"],
                                   map["_estimated"] == true,
                                   map["_dataAbsent"] == true);
}

class MeterGraph
{
  String name;
  List<String> meterNames;

  MeterGraph(this.name, this.meterNames);

  MeterGraph.fromMap(Map map) : this(map["_name"],
                                     map["_meterNames"]);

  static List<MeterGraph> create(List<Map> list)
  {
    List<MeterGraph> meterGraphs = new List();

    if (list != null) {
      for (Map map in list) {
        MeterGraph graph = new MeterGraph.fromMap(map);

        meterGraphs.add(graph);
      }
    }

    return meterGraphs;
  }

  @override
  String toString()
  {
    return "MeterGraph[$name,$meterNames]";
  }
}

class MeterGraphSection
{
  String name;
  List<MeterGraph> meterGraphs;

  MeterGraphSection(this.name, this.meterGraphs);

  MeterGraphSection.fromMap(Map map) : this(map["_name"],
                                            MeterGraph.create(map["_meterGraphs"]));

  static List<MeterGraphSection> create(List<Map> list)
  {
    List<MeterGraphSection> sectionList = new List();

    if (list != null) {
      for (Map map in list) {
        MeterGraphSection section = new MeterGraphSection.fromMap(map);

        sectionList.add(section);
      }
    }

    return sectionList;
  }

  @override
  String toString()
  {
    return "MeterGraphSection[$name,$meterGraphs]";
  }
}

class MeterGraphPage
{
  String name;
  int columns;
  int period;

  bool isSummary;
  bool isLog;
  bool isHeapDump;
  bool isProfile;
  bool isThreadDump;
  bool isJmxDump;

  List<MeterGraphSection> meterSections;
  List<MeterGraph> meterGraphs;

  MeterGraphPage(this.name, this.columns, this.period,
                 this.isSummary, this.isLog, this.isHeapDump,
                 this.isProfile, this.isThreadDump, this.isJmxDump,
                 this.meterSections, this.meterGraphs);

  MeterGraphPage.fromMap(Map map) : this(map["_name"],
                                         map["_columns"],
                                         map["_period"],
                                         map["_isSummary"],
                                         map["_isLog"],
                                         map["_isHeapDump"],
                                         map["_isProfile"],
                                         map["_isThreadDump"],
                                         map["_isJmxDump"],
                                         MeterGraphSection.create(map["_meterSections"]),
                                         MeterGraph.create(map["_meterGraphs"]));

  @override
  String toString()
  {
    return "MeterGraphPage[$name,$columns,$period,$meterSections,$meterGraphs]";
  }
}
