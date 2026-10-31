import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/tokens.dart';

/// Six visual cells over one invisible field, so typing auto-advances,
/// backspace moves back and paste fills all six for free.
class CodeBoxes extends StatefulWidget {
  const CodeBoxes({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.showError = false,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final bool showError;

  @override
  State<CodeBoxes> createState() => _CodeBoxesState();
}

class _CodeBoxesState extends State<CodeBoxes> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final code = widget.controller.text;
        return Stack(
          children: [
            Row(
              spacing: PresenceSpace.s8,
              children: [
                for (var i = 0; i < 6; i++)
                  Expanded(
                    child: _box(i < code.length ? code[i] : '', i, code),
                  ),
              ],
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                alwaysIncludeSemantics: true,
                child: TextField(
                  key: const ValueKey('code-input'),
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) => widget.onSubmitted(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: '6-digit code',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _box(String digit, int i, String code) {
    final active = _focus.hasFocus && i == code.length.clamp(0, 5);
    final empty = digit.isEmpty;
    final border = widget.showError && empty
        ? Border.all(color: PresenceColors.ink, width: 2)
        : active
        ? Border.all(color: PresenceColors.deepTeal, width: 2)
        : Border.all(color: PresenceColors.hairline);
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PresenceColors.paper,
        borderRadius: BorderRadius.circular(PresenceRadius.input),
        border: border,
      ),
      child: Text(digit, style: PresenceType.mono(22)),
    );
  }
}
