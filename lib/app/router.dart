import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/member_store.dart';
import '../data/session_controller.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/signin/signin_screen.dart';
import '../features/signin/terms_screen.dart';
import '../widgets/member_scaffold.dart';

GoRouter buildRouter(SessionController session, MemberStore store) {
  GoRoute tab(String path, Widget Function() screen) => GoRoute(
    path: path,
    pageBuilder: (context, state) => NoTransitionPage(child: screen()),
  );

  return GoRouter(
    initialLocation: '/signin',
    refreshListenable: session,
    redirect: (context, state) {
      final path = state.uri.path;
      final onSignin = path.startsWith('/signin');
      final isLegal = path == '/privacy' || path == '/terms';
      if (!session.isSignedIn) {
        if (path == '/signin/terms' && !session.needsTerms) return '/signin';
        return onSignin || isLegal ? null : '/signin';
      }
      return onSignin ? '/home' : null;
    },
    routes: [
      GoRoute(
        path: '/signin',
        builder: (context, state) => SigninScreen(session: session),
        routes: [
          GoRoute(
            path: 'terms',
            builder: (context, state) => TermsScreen(session: session),
          ),
        ],
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const LegalScreen.privacy(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const LegalScreen.terms(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MemberScaffold(location: state.uri.path, child: child),
        routes: [
          tab('/home', () => HomeScreen(store: store)),
          tab('/history', () => HistoryScreen(store: store)),
          tab('/scan', () => ScanScreen(store: store)),
          tab('/plan', () => PlanScreen(store: store)),
          tab('/profile', () => ProfileScreen(store: store, session: session)),
        ],
      ),
    ],
  );
}
