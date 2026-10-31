import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';

const _tabs = [
  ('/home', 'Home', LucideIcons.house),
  ('/history', 'History', LucideIcons.calendar),
  ('/scan', 'Scan', LucideIcons.scanLine),
  ('/plan', 'Plan', LucideIcons.dumbbell),
  ('/profile', 'Profile', LucideIcons.user),
];

class MemberTabBar extends StatelessWidget {
  const MemberTabBar({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PresenceSpace.s8),
      decoration: BoxDecoration(
        color: PresenceColors.paper,
        borderRadius: BorderRadius.circular(PresenceRadius.tabBar),
      ),
      child: Row(
        spacing: PresenceSpace.s4,
        children: [
          for (final (path, label, icon) in _tabs)
            Expanded(
              child: _TabItem(
                label: label,
                icon: icon,
                isScan: path == '/scan',
                active: location.startsWith(path),
                onTap: () => context.go(path),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.isScan,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isScan;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strong = isScan || active;
    final fg = isScan
        ? PresenceColors.mist
        : active
        ? PresenceColors.ink
        : PresenceColors.muted;
    final bg = isScan
        ? PresenceColors.ink
        : active
        ? PresenceColors.tealWash
        : Colors.transparent;
    final radius = BorderRadius.circular(PresenceRadius.member);
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: radius,
        child: InkWell(
          key: ValueKey('tab-$label'),
          borderRadius: radius,
          hoverColor: PresenceColors.ink.withValues(alpha: 0.04),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: PresenceSpace.s4,
              children: [
                Icon(icon, size: 20, color: fg),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PresenceType.sans(
                    11,
                    height: 1,
                    weight: strong ? FontWeight.w600 : FontWeight.w400,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
