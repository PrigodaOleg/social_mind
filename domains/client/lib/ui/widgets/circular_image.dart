import 'package:flutter/material.dart';

class CircularImage extends StatelessWidget {
  const CircularImage({super.key, this.imageRadius = 60, this.imageUrl});
  final double imageRadius;
  final imageUrl;

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
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
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
