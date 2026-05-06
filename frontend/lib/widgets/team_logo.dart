import 'package:flutter/material.dart';

class TeamLogo extends StatelessWidget {
  final String url;
  final double size;

  const TeamLogo({super.key, required this.url, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final fallback = Icon(Icons.shield, size: size * 0.78, color: muted);

    if (url.isEmpty) {
      return SizedBox(width: size, height: size, child: fallback);
    }
    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
