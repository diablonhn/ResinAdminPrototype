library Graph;

import 'package:js/js.dart' as js;
import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'env.dart';
import 'ResinStatService.dart';

class Graph
{
  static List<String> COLOR_LIST = ["#ff3030",  // red
                                    "#30b0ff",  // azure
                                    "#906000",  // brown
                                    "#ff9030",  // orange
                                    "#3030ff",  // blue
                                    "#000000",  // black
                                    "#50b000",  // green
                                    "#d030d0",  // magenta
                                    "#008080",  // cyan
                                    "#b03060",  // rose
                                    "#e090ff",  // indigo
                                    "#c0c0c0",  // gray
                                    "#408040"]; // forest green

  String title;
  String containerId;

  String hostId;
  String legendId;

  int legendColumns;

  Map<String,List<List<num>>> valueMap = new LinkedHashMap();

  Graph(this.title, this.containerId,
        {bool isShowLegendAtBottom : true,
         String cssClass : "mini-graph",
         int legendColumns : 1})
  {
    Element container = query("#$containerId");
    this.hostId = "$containerId-graph";

    DivElement titleDiv = new DivElement();
    titleDiv.innerHtml = this.title;
    titleDiv.classes.add("mini-title");
    container.append(titleDiv);

    DivElement graphDiv = new DivElement();
    graphDiv.id = this.hostId;
    graphDiv.classes.add(cssClass);
    container.append(graphDiv);

    if (isShowLegendAtBottom) {
      this.legendId = "$containerId-mini-legend";
      this.legendColumns = legendColumns;

      DivElement legendDiv = new DivElement();
      legendDiv.id = this.legendId;
      legendDiv.classes.add("mini-legend");
      container.append(legendDiv);
    }
  }

  void addPoint(String key, List<num> point)
  {
    List<List<num>> list = this.valueMap[key];

    if (list == null) {
       list = new List();

       this.valueMap[key] = list;
    }

    list.add(point);
  }

  void setPoints(String key, List<List<num>> points)
  {
    this.valueMap[key] = points;
  }

  void plot()
  {
    var jQuery = js.context.jQuery;

    List list = new List();

    int i = 0;
    valueMap.forEach((String key, List<List<num>> points) {
      String color = COLOR_LIST[i++ % COLOR_LIST.length];

      Map map = {"label" : key,
                 "color" : color,
                 "data" : points};

      list.add(map);
    });

    Map options = new Map();

    Object tickCallback = new js.Callback.many(tickFormatter);

    options["xaxis"] = {"mode" : "time",
                        "timezone" : "browser"};
    options["yaxis"] = {"tickFormatter" : tickCallback};

    if (this.legendId != null) {
      options["legend"] = {"container" : "#$legendId",
                           "noColumns" : this.legendColumns};
    }

    jQuery.plot("#$hostId", js.array(list), js.map(options));

    this.valueMap.clear();
  }

  String tickFormatter(num value, axis)
  {
    if (value >= 1e9) {
      return (value / 1e9).toStringAsFixed(1) + "G";
    }
    else if (value >= 1e6) {
      return (value / 1e6).toStringAsFixed(1) + "M";
    }
    else if (value > 1e3) {
      return (value / 1e3).toStringAsFixed(1) + "k";
    }
    else {
      return value.toStringAsFixed(axis.tickDecimals);
    }
  }

  void remove()
  {
    query("#$containerId").children.clear();
  }
}

class GraphUpdateService
{
  int updateInterval;

  int periodStartTime;
  int periodEndTime;

  int period;

  Timer timer;

  List<GraphEntry> graphList = new List();

  GraphUpdateService(int updateInterval, int periodStartTime)
  {
    setPeriod(updateInterval, periodStartTime, null);
  }

  GraphUpdateService.once(int periodStartTime, int periodEndTime)
  {
    setPeriod(null, periodStartTime, periodEndTime);
  }

  void setPeriod(int updateInterval, int periodStartTime, int periodEndTime)
  {
    this.updateInterval = updateInterval;
    this.periodStartTime = periodStartTime;
    this.periodEndTime = periodEndTime;
  }

  void addGraph(Graph graph, Map<String,String> statNameMap)
  {
    GraphEntry entry = new GraphEntry(graph, statNameMap);

    this.graphList.add(entry);
  }

  void scheduleTimer()
  {
    Duration duration = new Duration(milliseconds : this.updateInterval);
    this.timer = new Timer(duration, start);
  }

  void start()
  {
    int endTime = this.periodEndTime;

    if (endTime == null) {
      endTime = new DateTime.now().millisecondsSinceEpoch;
    }

    if (this.period == null) {
      this.period = endTime - this.periodStartTime;
    }

    ResinStatService statService = Env.getEnv().getResinStatService();

    List<Future> futureList = new List();

    for (GraphEntry entry in this.graphList) {
      entry.statNameMap.forEach((String name, String value) {
        Future<List<StatValue>> future
          = statService.getData(null, value, this.periodStartTime, endTime);

        future.then((List<StatValue> list) {
          for (StatValue stat in list) {
            entry.graph.addPoint(name, [stat.time, stat.sum ~/ stat.count]);
          }
        });

        futureList.add(future);
      });

      Future<List<Future>> wait = Future.wait(futureList);

      wait.then((List<Future> list) {
        entry.graph.plot();
      });
    }

    if (this.updateInterval != null) {
      this.periodStartTime = endTime - period + this.updateInterval;

      scheduleTimer();
    }
  }

  void stop()
  {
    this.timer.cancel();
  }
}

class GraphEntry
{
  Graph graph;
  Map<String,String> statNameMap;

  GraphEntry(this.graph, this.statNameMap);
}
