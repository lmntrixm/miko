import 'package:flutter/material.dart';

import '../theme/miko_colors.dart';
import '../theme/miko_tokens.dart';

/// Signature field: label sits on the top border, 1px red-600 outline,
/// focus → 2px red-400, error → danger, disabled → switch-off.
class MikoTextField extends StatefulWidget {
  const MikoTextField({
    super.key,
    required this.label,
    this.controller,
    this.icon,
    this.hint,
    this.errorText,
    this.obscure = false,
    this.ltr = false,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.labelBackground,
  });

  final String label;
  final TextEditingController? controller;
  final IconData? icon;
  final String? hint;
  final String? errorText;

  /// Password field: adds a show/hide toggle. Implies [ltr].
  final bool obscure;

  /// Email, password, codes: force left-to-right text.
  final bool ltr;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  /// Color behind the label on the border; match the surface the field sits on.
  final Color? labelBackground;

  @override
  State<MikoTextField> createState() => _MikoTextFieldState();
}

class _MikoTextFieldState extends State<MikoTextField> {
  final _focus = FocusNode();
  late bool _hidden = widget.obscure;

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
    final c = context.mr;
    final hasError = widget.errorText != null;
    final focused = _focus.hasFocus;
    final Color border = !widget.enabled
        ? c.switchOff
        : hasError
        ? c.danger
        : focused
        ? c.red400
        : c.red600;
    final Color labelColor = !widget.enabled
        ? c.textHint
        : hasError
        ? c.danger
        : focused
        ? c.red300
        : c.textMuted;
    final ltr = widget.ltr || widget.obscure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 64,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: MRSpacing.space4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(MRRadius.radius2xl),
                border: Border.all(
                  color: border,
                  width: focused || hasError ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 22, color: labelColor),
                    const SizedBox(width: MRSpacing.space3),
                  ],
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      obscureText: _hidden,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      textDirection: ltr ? TextDirection.ltr : null,
                      textAlign: ltr ? TextAlign.left : TextAlign.start,
                      cursorColor: c.red400,
                      style: MRText.bodyLg.copyWith(
                        color: widget.enabled ? c.textPrimary : c.textHint,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: widget.hint,
                        hintStyle: MRText.bodyLg.copyWith(color: c.textHint),
                      ),
                    ),
                  ),
                  if (widget.obscure)
                    Semantics(
                      button: true,
                      label: _hidden ? 'نمایش رمز' : 'پنهان کردن رمز',
                      child: GestureDetector(
                        onTap: () => setState(() => _hidden = !_hidden),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            _hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 22,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            PositionedDirectional(
              top: -10,
              start: MRSpacing.space5,
              child: Container(
                color: widget.labelBackground ?? c.bgPage,
                padding: const EdgeInsets.symmetric(
                  horizontal: MRSpacing.space2,
                ),
                child: Text(
                  widget.label,
                  style: MRText.caption.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: MRSpacing.space1,
              start: MRSpacing.space4,
            ),
            child: Text(
              widget.errorText!,
              style: MRText.caption.copyWith(color: c.danger),
            ),
          ),
      ],
    );
  }
}
