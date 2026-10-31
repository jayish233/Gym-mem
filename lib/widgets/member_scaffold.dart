import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'member_tab_bar.dart';

/// Centred 480 px column with the tab bar pinned below the scroll view.
class MemberScaffold extends StatelessWidget {
  const MemberScaffold({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(child: child),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: MemberTabBar(location: location),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrolling page body: padding 20 16 16, gap 28.
class MemberColumn extends StatelessWidget {
  const MemberColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PresenceSpace.s28,
      children: children,
    ),
  );
}
