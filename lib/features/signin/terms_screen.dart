import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/api_client.dart';
import '../../data/session_controller.dart';
import '../../theme/tokens.dart';
import '../../widgets/presence_button.dart';
import '../../widgets/presence_text_field.dart';
import 'signin_screen.dart';
import 'widgets/brand_pane.dart';

/// First sign-in only: the server records acceptance once.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _sending = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      // On success the router redirect moves us to /home.
      await widget.session.acceptTerms();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = PresenceType.sans(15, color: PresenceColors.ink);
    return SigninLayout(
      form: SigninForm(
        title: 'Before you start',
        sub: 'Read and accept the Terms of Service and Privacy Policy.',
        children: [
          Wrap(
            spacing: PresenceSpace.s20,
            children: [
              PresenceButton(
                label: 'Terms of Service',
                variant: ButtonVariant.text,
                textStyle: link,
                onPressed: () => context.push('/terms'),
              ),
              PresenceButton(
                label: 'Privacy Policy',
                variant: ButtonVariant.text,
                textStyle: link,
                onPressed: () => context.push('/privacy'),
              ),
            ],
          ),
          if (_error != null) FieldError(_error!),
          PresenceButton(
            label: 'Accept and continue',
            variant: ButtonVariant.key,
            loading: _sending,
            onPressed: _accept,
          ),
          Center(
            child: PresenceButton(
              label: 'Use a different account',
              variant: ButtonVariant.text,
              textStyle: PresenceType.sans(14, color: PresenceColors.muted),
              onPressed: () {
                widget.session.signOut();
                context.go('/signin');
              },
            ),
          ),
        ],
      ),
    );
  }
}
