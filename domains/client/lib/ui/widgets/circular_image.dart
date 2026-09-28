import 'dart:typed_data';

import 'package:flutter/material.dart';

class CircularImage extends StatelessWidget {
  const CircularImage({super.key, this.imageRadius = 60, this.imageBytes});
  final double imageRadius;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: imageRadius,
        backgroundColor: Colors.blue.shade100,
        backgroundImage: imageBytes != null ? MemoryImage(imageBytes!) : null,
        child: imageBytes == null
            ? const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
