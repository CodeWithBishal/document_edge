import 'dart:ui';
import 'package:flutter/material.dart';

import 'magnifier_painter.dart';

class DMagnifier extends StatefulWidget {
  const DMagnifier({
    required this.child,
    required this.position,
    this.visible = true,
    this.scale = 1.5,
    this.size = const Size(160, 160),
    super.key,
  });

  final Widget child;
  final Offset position;
  final bool visible;
  final double scale;
  final Size size;

  @override
  _DMagnifierState createState() => _DMagnifierState();
}

class _DMagnifierState extends State<DMagnifier> {
  Size? _magnifierSize;
  double? _scale;
  Matrix4? _matrix;

  @override
  void initState() {
    _magnifierSize = widget.size;
    _scale = widget.scale;
    _calculateMatrix();

    super.initState();
  }

  @override
  void didUpdateWidget(DMagnifier oldWidget) {
    super.didUpdateWidget(oldWidget);

    _calculateMatrix();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [widget.child, if (widget.visible) _getMagnifier(context)],
    );
  }

  void _calculateMatrix() {
    setState(() {
      double newX = widget.position.dx - (_magnifierSize!.width / 2 / _scale!);
      double newY = widget.position.dy - (_magnifierSize!.height / 2 / _scale!);

      Future.delayed(const Duration(seconds: 2), () {});

      if (_bubbleCrossesMagnifier()) {
        try {
          final box = context.findRenderObject() as RenderBox;
          newX -= ((box.size.width - _magnifierSize!.width) / _scale!);
        } catch (e) {
          print("Can't get render");
        }
      }

      final Matrix4 updatedMatrix = Matrix4.identity()
        ..scale(_scale, _scale)
        ..translate(-newX, -newY);

      _matrix = updatedMatrix;
    });
  }

  Widget _getMagnifier(BuildContext context) {
    return Align(
      alignment: _getAlignment(),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.matrix(_matrix!.storage),
          child: CustomPaint(
            painter: MagnifierPainter(
                color: Theme.of(context).colorScheme.secondary),
            size: _magnifierSize!,
          ),
        ),
      ),
    );
  }

  Alignment _getAlignment() {
    if (_bubbleCrossesMagnifier()) {
      return Alignment.topRight;
    }

    return Alignment.topLeft;
  }

  bool _bubbleCrossesMagnifier() =>
      widget.position.dx < widget.size.width &&
      widget.position.dy < widget.size.height;
}
