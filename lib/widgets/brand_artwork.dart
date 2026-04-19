import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 420, this.opacity = 1});

  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.asset('secura_logo.png', width: width, fit: BoxFit.contain),
    );
  }
}

class BrandBackground extends StatelessWidget {
  const BrandBackground({
    super.key,
    required this.child,
    this.logoWidth = 140,
    this.logoOpacity = 0.6,
    this.right = 16,
    this.bottom = 16,
  });

  final Widget child;
  final double logoWidth;
  final double logoOpacity;
  final double right;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          right: right,
          bottom: bottom,
          child: IgnorePointer(
            child: BrandLogo(width: logoWidth, opacity: logoOpacity),
          ),
        ),
      ],
    );
  }
}
