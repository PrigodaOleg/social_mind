import 'package:flutter/widgets.dart';
// import 'flutter_graph_view_wrapper.dart';
import 'graphview_wrapper.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract class Vertex extends StatefulWidget {
  String? caption;
  late void Function(ValueKey)? onSelect;
  late void Function(ValueKey)? onHintRequest;
  late void Function(ValueKey, String)? onCaptionChanging;
  late void Function(ValueKey, String)? onCaptionChanged;
  Vertex({this.caption,
         super.key,
         this.onSelect,
         this.onHintRequest,
         this.onCaptionChanging,
         this.onCaptionChanged});
}

class Edge {
  void onTap() {
  }
}

class GraphWidget extends StatefulWidget{
  // Виджет принимает граф, который нужно отобразить, в виде списка вершин и рёбер
  List<Vertex> vertexes = [];
  List<Edge> edges = [];
  // factory GraphWidget.gw() => FlutterGraphViewWrapper();
  factory GraphWidget.gw() => GraphViewWrapper();
  GraphWidget({super.key});

  @override
  State<GraphWidget> createState() => _GraphWidgetState();

  void addVertex(ValueKey key,
                {String? caption,
                 void Function(ValueKey)? onSelect,
                 void Function(ValueKey)? onHintRequest,
                 void Function(ValueKey, String)? onCaptionChanging,
                 void Function(ValueKey, String)? onCaptionChanged}) {
    throw UnimplementedError();
  }

  void addEdge(String? caption,
              ValueKey sourceVertex,
              ValueKey destinationVertex) {
    throw UnimplementedError();
  }
}

class _GraphWidgetState extends State<GraphWidget> {

  @override
  Widget build(BuildContext context) {
    // return GraphViewWrapper();
    return const Text('_GraphWidgetState');
  }
}