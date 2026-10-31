import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/session_controller.dart';
import '../../theme/tokens.dart';
import '../../widgets/presence_button.dart';
import '../../widgets/presence_text_field.dart';
import 'signin_screen.dart';
import 'widgets/brand_pane.dart';
import 'widgets/code_boxes.dart';

class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final _code = TextEditingController();
  bool _showError = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _code.addListener(() {
      if (_showError && _code.text.length == 6) {
        setState(() => _showError = false);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length < 6) {
      setState(() => _showError = true);
      return;
    }
    setState(() => _verifying = true);
    // On success the router redirect moves us to /home.
    final ok = await widget.session.verify(_code.text);
    if (mounted && !ok) setState(() => _verifying = false);
  }

  @override
  Widget build(BuildContext context) {
    return SigninLayout(
      form: SigninForm(
        title: 'Enter your code',
        sub: 'We emailed you a 6-digit code. It expires in 10 minutes.',
        children: [
          CodeBoxes(
            controller: _code,
            onSubmitted: _verify,
            showError: _showError,
          ),
          if (_showError) const FieldError('Enter all 6 digits.'),
          PresenceButton(
            label: 'Verify and continue',
            variant: ButtonVariant.key,
            loading: _verifying,
            onPressed: _code.text.length == 6 ? _verify : null,
          ),
          Center(
            child: PresenceButton(
              label: 'Use a different email',
              variant: ButtonVariant.text,
              textStyle: PresenceType.sans(14, color: PresenceColors.muted),
              onPressed: () {
                _code.clear();
                context.go('/signin');
              },
            ),
          ),
        ],
      ),
    );
  }
}
