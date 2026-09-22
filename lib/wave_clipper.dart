import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  const WaveClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(0, 0.7692 * h)
      ..cubicTo(0.2821 * w, 0.9038 * h, 0.4103 * w, 0.9038 * h, 0.5 * w, 0.8269 * h)
      ..cubicTo(0.5897 * w, 0.75 * h, 0.7179 * w, 0.6154 * h, w, 0.6923 * h)
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant WaveClipper oldClipper) => false;
}
