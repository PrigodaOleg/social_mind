import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:touchable/touchable.dart';

import 'graph_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

typedef VertexContext = ({
  String? caption,
  ValueKey key,
  void Function(ValueKey)? onSelect,
  void Function(ValueKey)? onHintRequest,
  void Function(ValueKey, String)? onCaptionChanging,
  void Function(ValueKey, String)? onCaptionChanged
});

class LineEdgeRenderer extends ArrowEdgeRenderer {
  @override
  List<double> drawTriangle(canvas, Paint paint, double x1, double y1, double x2, double y2) => [x2, y2];
  
  // @override
  // void render(BuildContext context,  canvas, Graph graph, Paint paint, {Offset? lastTappedPosition}) {
  //   super.render(context, canvas, graph, paint);
  //   graph.edges.forEach((edge) {
  //     var source = edge.source;
  //     var destination = edge.destination;
  //     var paint = edge.paint;
  //     var width =  paint != null ? paint.strokeWidth : 1;
  //     // if 
  //   });
  // }
}

class GraphViewVertex extends Vertex {
  GraphViewVertex({super.caption,
                   super.key,
                   super.onSelect,
                   super.onHintRequest,
                   super.onCaptionChanging,
                   super.onCaptionChanged});
  GraphViewVertex.Context(VertexContext context, {super.key}) {
    super.caption = context.caption;
    super.onSelect = context.onSelect;
    super.onHintRequest = context.onHintRequest;
    super.onCaptionChanging = context.onCaptionChanging;
    super.onCaptionChanged = context.onCaptionChanged;
  }
  @override
  State<Vertex> createState() => _VertexState();
}

class _VertexState extends State<Vertex> {
  String defaultCaption = '+';
  bool isReadOnly = false;
  bool isEnabled = false;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  bool selected = false;
  bool hovered = false;
  bool editing = false;
  double radius = 10.0;

  @override
  void initState() {
    _textController = TextEditingController(text: widget.caption);
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {print('_focusNode has focus ${_focusNode.hasFocus}');});
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          selected = true;
          widget.onSelect?.call(widget.key as ValueKey);
        });
      },
      onHover: (value) {
        setState(() {
          hovered = value;
          _focusNode.requestFocus();
          if (value) {
            widget.onHintRequest?.call(widget.key as ValueKey);
          }
        });
      },
      onLongPress: () {
        setState(() {
          isEnabled = true;
          FocusScope.of(context).requestFocus(_focusNode);
        });
        _focusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 237, 232, 168),
          border: Border.all(color: hovered ?
            const Color.fromARGB(116, 228, 128, 128) :
            const Color.fromARGB(255, 225, 200, 200),
            width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Color.fromARGB(227, 241, 230, 145), spreadRadius: 2),],
        ),
        child: IntrinsicWidth(
          child: CupertinoTextField(
            // readOnly: true,
            controller: _textController,
            focusNode: _focusNode..requestFocus(),
            style: const TextStyle(),
            cursorColor: Colors.black38,
            readOnly: isReadOnly,
            enabled: isEnabled,
            autofocus: true,
            onChanged: (value) {
              // captions[key] = value;
            },
            onTapOutside: (event) {
              setState(() {
                isEnabled = false;
              });
            },
            onSubmitted: (value) {
              setState(() {
                isEnabled = false;
              });
            },
            placeholder: defaultCaption,
            // showCursor: true,
          )
        )
      ),
    );
  }
}

class GraphViewWrapper extends GraphWidget {
// class GraphViewWrapper extends GraphWidget {
  GraphViewWrapper({super.key});
  Graph graph = Graph();

  final _GraphViewWrapperState _state = _GraphViewWrapperState();

  @override
  State<GraphViewWrapper> createState() => _state;

  @override
  void addVertex(ValueKey key,
                 {String? caption,
                 void Function(ValueKey)? onSelect,
                 void Function(ValueKey)? onHintRequest,
                 void Function(ValueKey, String)? onCaptionChanging,
                 void Function(ValueKey, String)? onCaptionChanged}) {
    _state.vertexContext[key] = (caption: caption ?? '',
                                 key: key,
                                 onSelect: onSelect,
                                 onHintRequest: onHintRequest,
                                 onCaptionChanging: onCaptionChanging,
                                 onCaptionChanged: onCaptionChanged);
    _state.addVertex(key);
  }

  @override
  void addEdge(String? caption,
               ValueKey sourceVertex,
               ValueKey destinationVertex) {
    _state.addEdge(caption, sourceVertex, destinationVertex);
  }
}

class _GraphViewWrapperState extends State<GraphViewWrapper> {
  int lastId = 0;
  GlobalKey stickyKey = GlobalKey();

  Map<ValueKey, VertexContext> vertexContext = {};
  bool isEnabled = true;

  void addEdge(String? caption,
               ValueKey sourceVertex,
               ValueKey destinationVertex) {
    setState(() {
      var source = widget.graph.getNodeUsingId(sourceVertex); 
      var destination = widget.graph.getNodeUsingId(destinationVertex); 
      widget.graph.addEdge(source, destination);
    });
  }

  void addVertex(ValueKey key) {
    setState(() {
      _addNode(key);
    });
  }

  Node _addNode(ValueKey key, {Offset? position}) {
    if (position == null) {
      final box = stickyKey.currentContext!.findRenderObject() as RenderBox;
      position = Offset(box.size.height/2, box.size.width/2);
    }
    Node node = Node.Id(key)..position=position;
    widget.graph.addNode(node);
    return node;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.01,
        maxScale: 5.6,
        child: GraphView(
          key: stickyKey,
          graph: widget.graph,
          algorithm: FruchtermanReingoldAlgorithm(
            renderer:  LineEdgeRenderer(),
            iterations: 100
          ),
          paint: Paint()
            ..color = Colors.green
            ..strokeWidth = 1
            ..style = PaintingStyle.fill,
          builder: (Node node) {
            // I can decide what widget should be shown here based on the id
            var a = node.key!.value;
            var vert = GraphViewVertex.Context(vertexContext[a]!, key: a);
            return vert;
            // return vertexWidget(a, captions[a]);
          },
        )
      ),
    );
  }
}