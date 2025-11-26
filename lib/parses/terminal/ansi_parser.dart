import 'package:flutter/material.dart';
import 'package:laravelide/utils/terminal_style/terminal_color.dart';

TextSpan parseAnsi(String text) {
  final spans = <TextSpan>[];

  // ANSI pattern example: \x1B[31m
  final ansiRegex = RegExp(r'\x1B\[[0-9;]*m');

  Color currentColor = Colors.white;

  final matches = ansiRegex.allMatches(text);
  int currentIndex = 0;

  for (final match in matches) {
    if (match.start > currentIndex) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex, match.start),
          style: TextStyle(color: currentColor, fontSize: 13),
        ),
      );
    }

    final code = match.group(0)!;

    // reset
    if (code == "\x1B[0m") {
      currentColor = Colors.white;
    }

    if (code.contains("[31")) currentColor = TerminalColor.red;
    if (code.contains("[33")) currentColor = TerminalColor.yellow;
    if (code.contains("[32")) currentColor = TerminalColor.green;
    if (code.contains("[36")) currentColor = TerminalColor.cyan;
    if (code.contains("[34")) currentColor = TerminalColor.blue;

    currentIndex = match.end;
  }

  if (currentIndex < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(currentIndex),
        style: TextStyle(color: currentColor, fontSize: 13),
      ),
    );
  }

  return TextSpan(children: spans);
}
