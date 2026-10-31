import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api_client.dart';
import '../../data/member_store.dart';
import '../../data/session_controller.dart';
import '../../theme/tokens.dart';
import '../../widgets/avatar.dart';
import '../../widgets/figure.dart';
import '../../widgets/hairline.dart';
import '../../widgets/member_scaffold.dart';
import '../../widgets/presence_button.dart';
import '../../widgets/presence_text_field.dart';
import '../../widgets/status_dot.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.store, required this.session});

  final MemberStore store;
  final SessionController session;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _name = TextEditingController(text: widget.store.member.name);
  late final _phone = TextEditingController(text: widget.store.member.phone);
  late final _email = TextEditingController(text: widget.store.member.email);
  bool _saved = false;
  bool _saving = false;
  String? _nameError;
  String? _saveError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _edited(String _) {
    if (_saved) setState(() => _saved = false);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = 'Enter your name.');
      return;
    }
    setState(() {
      _nameError = null;
      _saveError = null;
      _saving = true;
    });
    try {
      await widget.store.saveProfile(name: _name.text, phone: _phone.text);
      if (mounted) setState(() => _saved = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _saveError = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // The router redirect takes us to /signin. Attendance and the plan stay
  // on the server.
  void _signOut() => widget.session.signOut();

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final date = DateFormat('d MMM yyyy');
    final dateStyle = PresenceType.mono(15);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MemberColumn(
        children: [
          Row(
            spacing: PresenceSpace.s16,
            children: [
              Avatar(initials: store.member.initials, size: 64),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: PresenceSpace.s4,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        store.member.name,
                        style: PresenceType.pageTitle,
                      ),
                    ),
                    Text(
                      store.gymName,
                      style: PresenceType.sans(14, color: PresenceColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // shortcut: 3 fixed columns (fits 390 wide), not an auto-fit grid;
          // switch to a Wrap if longer values are added.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PresenceSpace.s16,
            children: [
              Expanded(
                child: Figure(
                  label: 'Membership',
                  value: '',
                  highlight: true,
                  valueChild: store.membershipActive
                      ? const StatusDot(
                          kind: DotKind.present,
                          word: 'Active',
                          color: PresenceColors.deepTeal,
                        )
                      : const StatusDot(kind: DotKind.closed, word: 'Expired'),
                ),
              ),
              Expanded(
                child: Figure(
                  label: 'Started',
                  value: date.format(store.membership.start),
                  valueStyle: dateStyle,
                ),
              ),
              Expanded(
                child: Figure(
                  label: 'Ends',
                  value: date.format(store.membership.end),
                  valueStyle: dateStyle,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18,
            children: [
              PresenceTextField(
                label: 'Name',
                controller: _name,
                autofillHints: const [AutofillHints.name],
                onChanged: _edited,
                error: _nameError,
              ),
              PresenceTextField(
                label: 'Phone',
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                onChanged: _edited,
              ),
              PresenceTextField(
                label: 'Email',
                controller: _email,
                readOnly: true,
                helper: 'Email is set by your gym. Ask them to change it.',
              ),
              if (_saveError != null) FieldError(_saveError!),
              PresenceButton(
                label: _saved ? 'Saved' : 'Save changes',
                height: 56,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
          Column(
            children: [
              _LegalRow('Privacy Policy', () => context.push('/privacy')),
              _LegalRow('Terms of Service', () => context.push('/terms')),
              const Hairline(),
            ],
          ),
          PresenceButton(
            label: 'Sign out',
            variant: ButtonVariant.secondary,
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  const _LegalRow(this.title, this.onTap);

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        hoverColor: PresenceColors.ink.withValues(alpha: 0.04),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: const BoxDecoration(border: hairlineTop),
          child: Row(
            children: [
              Expanded(child: Text(title, style: PresenceType.body)),
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: PresenceColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
