import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/session_controller.dart';
import '../../theme/tokens.dart';
import '../../widgets/presence_button.dart';
import '../../widgets/presence_text_field.dart';
import 'widgets/brand_pane.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _email = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!SessionController.isValidEmail(_email.text)) {
      setState(() => _error = 'Enter the email your gym has on file.');
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    await widget.session.sendCode(_email.text);
    if (!mounted) return;
    setState(() => _sending = false);
    context.go('/signin/code');
  }

  @override
  Widget build(BuildContext context) {
    return SigninLayout(
      form: SigninForm(
        title: 'Sign in',
        sub: 'Check in and keep your streak.',
        children: [
          PresenceTextField(
            key: const ValueKey('email'),
            label: 'Email',
            controller: _email,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _submit(),
            error: _error,
          ),
          PresenceButton(
            label: 'Send code',
            loading: _sending,
            onPressed: _submit,
          ),
          const _LegalFooter(),
        ],
      ),
    );
  }
}

/// Title + sub + fields, shared by both sign-in steps.
class SigninForm extends StatelessWidget {
  const SigninForm({
    super.key,
    required this.title,
    required this.sub,
    required this.children,
  });

  final String title;
  final String sub;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: PresenceSpace.s16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: PresenceSpace.s8,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: wide
                    ? PresenceType.sans(
                        32,
                        height: 1.1,
                        weight: FontWeight.w600,
                        em: -0.025,
                      )
                    : PresenceType.pageTitle,
              ),
            ),
            Text(sub, style: PresenceType.bodyMuted),
          ],
        ),
        const SizedBox(height: PresenceSpace.s8),
        ...children,
      ],
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final caption = PresenceType.caption;
    final link = PresenceType.sans(13, color: PresenceColors.ink);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('By continuing you agree to the ', style: caption),
        PresenceButton(
          label: 'Terms',
          variant: ButtonVariant.text,
          textStyle: link,
          onPressed: () => context.push('/terms'),
        ),
        Text(' and ', style: caption),
        PresenceButton(
          label: 'Privacy Policy',
          variant: ButtonVariant.text,
          textStyle: link,
          onPressed: () => context.push('/privacy'),
        ),
        Text('.', style: caption),
      ],
    );
  }
}
