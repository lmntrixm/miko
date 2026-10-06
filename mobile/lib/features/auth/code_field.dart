import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/validators.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';

/// Six-digit code input: label on the border, underlined boxes, always LTR.
/// A hidden TextField receives typing/paste/autofill; Persian digits are normalised.
class CodeField extends StatefulWidget {
  const CodeField({
    super.key,
    required this.controller,
    this.label = 'کد ارسالی',
    this.errorText,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
  });
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final text = widget.controller.text;
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? c.danger
        : (_focus.hasFocus ? c.red400 : c.red600);
    final labelColor = hasError
        ? c.danger
        : (_focus.hasFocus ? c.red300 : c.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          textField: true,
          label: widget.label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _focus.requestFocus(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 70,
                  padding: const EdgeInsets.only(bottom: 16),
                  alignment: Alignment.bottomCenter,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(MRRadius.radius2xl),
                    border: Border.all(
                      color: borderColor,
                      width: _focus.hasFocus || hasError ? 2 : 1,
                    ),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < widget.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Container(
                            width: 36,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  width: 3,
                                  color: hasError
                                      ? c.danger
                                      : i < text.length
                                      ? c.red500
                                      : (i == text.length && _focus.hasFocus
                                            ? c.red400
                                            : c.switchOff),
                                ),
                              ),
                            ),
                            child: Text(
                              i < text.length ? text[i] : '',
                              style: MRText.h2.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Hidden input on top of the boxes.
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: widget.length,
                      inputFormatters: [
                        TextInputFormatter.withFunction((o, n) {
                          final d = normalizeDigits(n.text)
                              .replaceAll(RegExp(r'\D'), '');
                          final cut = d.length > widget.length
                              ? d.substring(0, widget.length)
                              : d;
                          return TextEditingValue(
                            text: cut,
                            selection: TextSelection.collapsed(
                              offset: cut.length,
                            ),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        widget.onChanged?.call(v);
                        if (v.length == widget.length) {
                          widget.onCompleted?.call(v);
                        }
                      },
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: -11,
                  start: 22,
                  child: Container(
                    color: c.bgPage,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      widget.label,
                      style: MRText.caption.copyWith(
                        fontSize: 13,
                        color: labelColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 4, start: 16),
            child: Text(
              widget.errorText!,
              style: MRText.caption.copyWith(color: c.danger),
            ),
          ),
      ],
    );
  }
}
