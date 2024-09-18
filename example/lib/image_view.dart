import 'dart:io';
import 'package:flutter/material.dart';

class ImageView extends StatefulWidget {
  const ImageView({Key? key, this.imagePath}) : super(key: key);

  final String? imagePath;

  @override
  _ImageViewState createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  GlobalKey imageWidgetKey = GlobalKey();

  @override
  Widget build(BuildContext mainContext) {
    return widget.imagePath != null
        ? Center(
            child: Image.file(File(widget.imagePath!), fit: BoxFit.contain))
        : const Center();
  }
}
