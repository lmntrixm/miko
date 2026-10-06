import 'package:flutter/material.dart';

/// Play triangle pointing toward the reading direction in RTL (left), like the design.
class PlayGlyph extends StatelessWidget {
  const PlayGlyph({super.key, required this.color, this.size = 24});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Transform.flip(flipX: true, child: Icon(Icons.play_arrow_rounded, color: color, size: size));
}
