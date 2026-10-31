import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/tokens.dart';
import '../../widgets/presence_button.dart';

/// Static placeholder legal page. No legal prose is written here on purpose.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.sections});

  const LegalScreen.privacy({super.key})
    : title = 'Privacy Policy',
      sections = const [
        (
          'What we collect',
          '[PLACEHOLDER: name, phone, email, attendance dates]',
        ),
        (
          'How we use it',
          '[PLACEHOLDER: check-ins, streaks, your gym seeing your visits]',
        ),
        (
          'Camera',
          '[PLACEHOLDER: used only while scanning, nothing recorded or stored]',
        ),
        (
          'Who can see it',
          '[PLACEHOLDER: you and your gym; your workout plan is only yours]',
        ),
        ('Your choices', '[PLACEHOLDER: how to correct or delete your data]'),
        ('Contact', '[PLACEHOLDER: contact details]'),
      ];

  const LegalScreen.terms({super.key})
    : title = 'Terms of Service',
      sections = const [
        (
          'Who these terms are for',
          '[PLACEHOLDER: gym members using Presence]',
        ),
        (
          'Your account',
          '[PLACEHOLDER: sign in with the email your gym has on file]',
        ),
        (
          'Checking in',
          '[PLACEHOLDER: one check-in per day by scanning the gym code]',
        ),
        ('Acceptable use', '[PLACEHOLDER: what you may and may not do]'),
        (
          'Changes to these terms',
          '[PLACEHOLDER: how we tell you about changes]',
        ),
      ];

  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 720;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(phone ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PresenceIconButton(
                    icon: LucideIcons.arrowLeft,
                    tooltip: 'Back',
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/signin'),
                  ),
                  const SizedBox(height: PresenceSpace.s16),
                  Semantics(
                    header: true,
                    child: Text(title, style: PresenceType.display(phone)),
                  ),
                  const SizedBox(height: PresenceSpace.s8),
                  Text(
                    'Last updated [PLACEHOLDER]',
                    style: PresenceType.caption,
                  ),
                  for (final (heading, body) in sections) ...[
                    const SizedBox(height: PresenceSpace.s40),
                    Semantics(
                      header: true,
                      child: Text(heading, style: PresenceType.section),
                    ),
                    const SizedBox(height: PresenceSpace.s8),
                    Text(
                      body,
                      style: PresenceType.sans(
                        16,
                        color: PresenceColors.graphite,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
