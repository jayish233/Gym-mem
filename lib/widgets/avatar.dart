import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Ink circle with mist initials.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: PresenceColors.ink,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: PresenceType.sans(
          size >= 64 ? 20 : 14,
          weight: FontWeight.w600,
          color: PresenceColors.mist,
        ),
      ),
    );
  }
}
