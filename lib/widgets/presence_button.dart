import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum ButtonVariant { primary, key, secondary, secondaryOnInk, text }

/// The one button in the design system (section 4.5).
class PresenceButton extends StatefulWidget {
  const PresenceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.height = 52,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.radius,
    this.textStyle,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final double height;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double? radius;

  /// Only for [ButtonVariant.text]: overrides the link style.
  final TextStyle? textStyle;
  final String? semanticsLabel;

  @override
  State<PresenceButton> createState() => _PresenceButtonState();
}

class _PresenceButtonState extends State<PresenceButton> {
  bool _hover = false;
  bool _focus = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _activate() {
    if (_enabled) widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final v = widget.variant;
    final isText = v == ButtonVariant.text;

    final Color fill = switch (v) {
      ButtonVariant.primary =>
        _hover ? PresenceColors.graphite : PresenceColors.ink,
      ButtonVariant.key =>
        _hover
            ? Color.lerp(PresenceColors.teal, PresenceColors.paper, 0.14)!
            : PresenceColors.teal,
      _ => Colors.transparent,
    };
    final Color fg = switch (v) {
      ButtonVariant.primary ||
      ButtonVariant.secondaryOnInk => PresenceColors.mist,
      ButtonVariant.text =>
        _hover ? PresenceColors.deepTeal : PresenceColors.ink,
      _ => PresenceColors.ink,
    };
    final Border? border = switch (v) {
      ButtonVariant.secondary => Border.all(color: PresenceColors.ink),
      ButtonVariant.secondaryOnInk => Border.all(color: PresenceColors.mist),
      _ => null,
    };
    final radius = widget.radius ?? (widget.height >= 56 ? 14.0 : 12.0);

    final labelStyle = isText
        ? (widget.textStyle ?? PresenceType.sans(14, weight: FontWeight.w500))
              .copyWith(
                decoration: TextDecoration.underline,
                decorationColor: widget.textStyle?.color ?? fg,
                color: _hover
                    ? PresenceColors.deepTeal
                    : widget.textStyle?.color ?? fg,
              )
        : PresenceType.sans(
            15,
            height: 1,
            weight: v == ButtonVariant.key || v == ButtonVariant.primary
                ? FontWeight.w600
                : FontWeight.w500,
            color: fg,
          );

    Widget content = widget.loading
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: labelStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    final box = AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      constraints: BoxConstraints(
        minHeight: isText ? 44 : widget.height,
        minWidth: 44,
      ),
      width: widget.expand && !isText ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: isText ? 0 : 18),
      // Text links shrink-wrap; an alignment would make them fill the row.
      alignment: isText ? null : Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        border: border,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: isText
          ? Center(widthFactor: 1, heightFactor: 1, child: content)
          : content,
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticsLabel,
      excludeSemantics: widget.semanticsLabel != null,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (h) => setState(() => _hover = h),
        onShowFocusHighlight: (f) => setState(() => _focus = f),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: _enabled ? _activate : null,
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: reduce
                ? Duration.zero
                : const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Opacity(
              opacity: widget.onPressed == null ? 0.4 : 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  box,
                  if (_focus)
                    Positioned.fill(
                      left: -4,
                      top: -4,
                      right: -4,
                      bottom: -4,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: PresenceColors.deepTeal,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(radius + 4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum IconButtonStyle { plain, outline, ink }

/// 44 px (or larger) icon-only button. Always carries a tooltip.
class PresenceIconButton extends StatelessWidget {
  const PresenceIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.style = IconButtonStyle.plain,
    this.size = 44,
    this.iconColor = PresenceColors.ink,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final IconButtonStyle style;
  final double size;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final side = switch (style) {
      IconButtonStyle.outline => BorderSide(
        color: enabled
            ? PresenceColors.ink.withValues(alpha: 0.2)
            : PresenceColors.hairline,
      ),
      _ => BorderSide.none,
    };
    final fg = style == IconButtonStyle.ink ? PresenceColors.mist : iconColor;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
        foregroundColor: fg,
        disabledForegroundColor: PresenceColors.ink.withValues(alpha: 0.35),
        backgroundColor: style == IconButtonStyle.ink
            ? PresenceColors.ink
            : Colors.transparent,
        hoverColor: PresenceColors.ink.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PresenceRadius.input),
          side: side,
        ),
      ),
    );
  }
}
