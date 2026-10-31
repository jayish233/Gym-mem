import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';

/// Label above a 52 px field (section 4.6).
class PresenceTextField extends StatelessWidget {
  const PresenceTextField({
    super.key,
    this.label,
    required this.controller,
    this.hint,
    this.error,
    this.helper,
    this.readOnly = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.mono = false,
    this.semanticLabel,
  });

  final String? label;
  final TextEditingController controller;
  final String? hint;
  final String? error;
  final String? helper;
  final bool readOnly;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool mono;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final textStyle = mono
        ? PresenceType.mono(16, weight: FontWeight.w400)
        : PresenceType.sans(16);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(PresenceRadius.input),
      borderSide: BorderSide(color: c, width: w),
    );
    final hasError = error != null;
    final field = SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        style: textStyle.copyWith(
          color: readOnly ? PresenceColors.muted : PresenceColors.ink,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: textStyle.copyWith(color: PresenceColors.muted),
          filled: true,
          fillColor: readOnly
              ? PresenceColors.ink.withValues(alpha: 0.05)
              : PresenceColors.paper,
          contentPadding: EdgeInsets.symmetric(horizontal: mono ? 12 : 16),
          enabledBorder: hasError
              ? border(PresenceColors.ink, 2)
              : border(PresenceColors.hairline),
          focusedBorder: border(
            hasError ? PresenceColors.ink : PresenceColors.deepTeal,
            2,
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          ExcludeSemantics(child: Text(label!, style: PresenceType.label)),
          const SizedBox(height: PresenceSpace.s8),
        ],
        Semantics(label: label ?? semanticLabel, child: field),
        if (hasError) ...[
          const SizedBox(height: PresenceSpace.s8),
          FieldError(error!),
        ] else if (helper != null) ...[
          const SizedBox(height: PresenceSpace.s8),
          Text(helper!, style: PresenceType.caption),
        ],
      ],
    );
  }
}

/// Icon + one sentence that says how to fix it. Never red.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      children: [
        const Icon(
          LucideIcons.circleAlert,
          size: 16,
          color: PresenceColors.ink,
        ),
        const SizedBox(width: PresenceSpace.s8),
        Expanded(child: Text(message, style: PresenceType.sans(13))),
      ],
    ),
  );
}
