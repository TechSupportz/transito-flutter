import 'package:flutter/material.dart';

class AppSymbol extends StatelessWidget {
  const AppSymbol(
    this.symbol, {
    super.key,
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
  });

  final IconData symbol;
  final double? size;
  final bool? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;
  final Color? color;
  final List<Shadow>? shadows;
  final String? semanticLabel;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Icon(
      symbol,
      size: size,
      fill: (fill ?? false) ? 1 : 0.0,
      weight: weight ?? 400,
      grade: grade,
      opticalSize: opticalSize ?? size ?? 24, // default when not provided
      color: color,
      shadows: shadows,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}
