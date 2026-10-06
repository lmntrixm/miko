import 'package:flutter/material.dart';

/// Shows a snackbar right away, replacing any message still on screen
/// (Flutter would otherwise queue it behind the old one for seconds).
void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
