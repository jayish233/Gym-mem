import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/member_store.dart';
import '../data/session_controller.dart';
import '../theme/presence_theme.dart';
import 'router.dart';

class PresenceApp extends StatefulWidget {
  const PresenceApp({super.key, required this.session, required this.store});

  final SessionController session;
  final MemberStore store;

  @override
  State<PresenceApp> createState() => _PresenceAppState();
}

class _PresenceAppState extends State<PresenceApp> {
  late final GoRouter _router = buildRouter(widget.session, widget.store);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Presence',
      debugShowCheckedModeBanner: false,
      theme: buildPresenceTheme(),
      routerConfig: _router,
    );
  }
}
