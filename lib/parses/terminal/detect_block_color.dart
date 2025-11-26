import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:laravelide/utils/terminal_style/terminal_color.dart';

Color detectBlockColor(String line, bool inError, bool inWarn) {
  final l = line.toLowerCase();

  if (inError) return TerminalColor.red;
  if (inWarn) return TerminalColor.yellow;

  if (l.contains("success") ||
      l.contains("built") ||
      l.contains("running") ||
      l.contains("√")) {
    return TerminalColor.green;
  }
  if (l.contains("connecting") || l.contains("connected")) {
    return TerminalColor.cyan;
  }
  if (l.contains("cmake") || l.contains("debug") || l.contains("info")) {
    return TerminalColor.blue;
  }

  return Colors.white;
}
