import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';

import 'graph_widget.dart';

class FlutterGraphViewWrapper extends GraphWidget {
// class GraphViewWrapper extends GraphWidget {
  FlutterGraphViewWrapper({super.key});
  Graph graph = Graph();

  final _FlutterGraphViewWrapperState _state = _FlutterGraphViewWrapperState();

  @override
  State<FlutterGraphViewWrapper> createState() => _state;

  // @override
  // Vertex addVertex(String caption) {
  //   // _state.addVertex(caption);
  //   return Vertex();
  // }
}

class _FlutterGraphViewWrapperState extends State<FlutterGraphViewWrapper> {
  
    var vertexes = <Map>{};
    var r = Random();
    var edges = <Map>{};
  
  @override
  Widget build(BuildContext context) {
    
    for (var i = 0; i < 200; i++) {
      vertexes.add(
        {
          'id': 'node$i',
          'tag': 'tag${r.nextInt(9)}',
          'tags': [
            'tag${r.nextInt(9)}',
            if (r.nextBool()) 'tag${r.nextInt(4)}',
            if (r.nextBool()) 'tag${r.nextInt(8)}'
          ],
        },
      );
    }

    for (var i = 0; i < 200; i++) {
      edges.add({
        'srcId': 'node${i % 4}',
        'dstId': 'node$i',
        'edgeName': 'edge${r.nextInt(3)}',
        'ranking': r.nextInt(DateTime.now().millisecond),
      });
    }

    for (var i = 0; i < 50; i++) {
      edges.add({
        'srcId': 'node1',
        'dstId': 'node2',
        'edgeName': 'edge${r.nextInt(3)}',
        'ranking': r.nextInt(DateTime.now().millisecond),
      });
    }

    var data = {
      'vertexes': vertexes,
      'edges': edges,
    };
    return SizedBox(
      height: 5000, 
      child: InteractiveViewer(
        constrained: true,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.01,
        maxScale: 5.6,
        child: FlutterGraphWidget(
          data: data,
          algorithm: ForceDirected(BreatheDecorator()),
          convertor: MapConvertor(),
        )
      )
    );
  }
}
