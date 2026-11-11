import 'package:flutter/material.dart';

class DandiyaVideo extends StatelessWidget {
  const DandiyaVideo({super.key, this.fit = BoxFit.contain});

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'DNFarytaleIamges/dan_gif.gif',
      fit: fit,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.image_not_supported_outlined)),
    );
  }
}
