import 'package:flutter/material.dart';

class StylexHighlighterController extends TextEditingController {
  final Map<String, TextStyle> _styleMap = {
    'default': const TextStyle(color: Color(0xFFD4D4D4)),
    'comment': const TextStyle(color: Color(0xFF6A9955)),
    'doc-comment': const TextStyle(
      color: Color(0xFF608B4E),
      fontStyle: FontStyle.italic,
    ),
    'string': const TextStyle(color: Color(0xFFCE9178)),
    'number': const TextStyle(color: Color(0xFFB5CEA8)),
    'boolean': const TextStyle(color: Color(0xFF569CD6)),
    'keyword': const TextStyle(color: Color(0xFFC586C0)),
    'modifier': const TextStyle(color: Color(0xFF569CD6)),
    'class': const TextStyle(color: Color(0xFF4EC9B0)),
    'enum': const TextStyle(color: Color(0xFFB8D7A3)),
    'function': const TextStyle(color: Color(0xFFDCDCAA)),
    'method': const TextStyle(color: Color(0xFFDCDCAA)),
    'constructor': const TextStyle(color: Color(0xFF4EC9B0)),
    'variable': const TextStyle(color: Color(0xFF9CDCFE)),
    'parameter': const TextStyle(color: Color(0xFF9CDCFE)),
    'property': const TextStyle(color: Color(0xFF9CDCFE)),
    'operator': const TextStyle(color: Color(0xFFD4D4D4)),
    'punctuation': const TextStyle(color: Color(0xFFD4D4D4)),
    'annotation': const TextStyle(color: Color(0xFFC586C0)),
    'import': const TextStyle(color: Color(0xFFC586C0)),
  };

  static const dartControlKeywords = {
    'if',
    'else',
    'switch',
    'case',
    'default',
    'for',
    'while',
    'do',
    'break',
    'continue',
    'return',
    'try',
    'catch',
    'finally',
    'throw',
    'rethrow',
    'assert',
  };

  static const dartModifiers = {
    'abstract',
    'async',
    'await',
    'const',
    'covariant',
    'dynamic',
    'export',
    'extends',
    'external',
    'factory',
    'final',
    'get',
    'implements',
    'import',
    'in',
    'interface',
    'late',
    'library',
    'mixin',
    'new',
    'operator',
    'part',
    'required',
    'set',
    'static',
    'typedef',
    'var',
    'void',
    'with',
  };

  static const Set<String> dartAnnotations = {
    '@override',
    '@Deprecated',
    '@pragma',
    '@immutable',
    '@protected',
    '@visibleForTesting',
    '@required',
  };

  static const dartTypes = {
    'int',
    'double',
    'String',
    'bool',
    'List',
    'Map',
    'Set',
    'Object',
    'Future',
    'Stream',
    'Null',
    'Never',
  };

  static const dartConstants = {'true', 'false', 'null'};

  static const flutterCoreClasses = {
    'Widget',
    'StatelessWidget',
    'StatefulWidget',
    'BuildContext',
    'State',
    'MaterialApp',
    'Scaffold',
    'AppBar',
    'Text',
    'Column',
    'Row',
    'Container',
    'Center',
    'Expanded',
    'Padding',
    'ListView',
    'FutureBuilder',
    'StreamBuilder',
    'Navigator',
    'Theme',
    'MediaQuery',
  };

  static const Set<String> _punctuation = {
    '{',
    '}',
    '(',
    ')',
    '[',
    ']',
    ';',
    ',',
    '.',
    ':',
    '?',
    '<',
    '>',
  };

  static const Set<String> _operators = {
    '=>',
    '=',
    '==',
    '!=',
    '===',
    '!==',
    '+',
    '-',
    '*',
    '/',
    '%',
    '>',
    '<',
    '>=',
    '<=',
    '&&',
    '||',
    '!',
    '??',
    '?.',
    '..',
    '&',
    '|',
    '^',
    '~',
  };

  static final Set<String> allKeywords = {
    ...dartControlKeywords,
    ...dartModifiers,
    ...dartTypes,
    ...dartConstants,
    ...flutterCoreClasses,
  };

  final RegExp _pattern = RegExp(
    r'''//[^\n]*|/\*[\s\S]*?\*/|@[\w]+|".*?"|'.*?'|\b\d+(\.\d+)?\b|\b\w+\b|(=>|[\{\}\(\)\[\];,\.!=\+\-\*\/<>&\|])''',
    multiLine: true,
  );

  final RegExp _wordRegExp = RegExp(r'^[A-Za-z_]\w*$');
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    final String currentText = text;
    String? previousWord;

    int lastMatchEnd = 0;

    for (final Match match in _pattern.allMatches(currentText)) {
      if (match.start > lastMatchEnd) {
        children.add(
          TextSpan(
            text: currentText.substring(lastMatchEnd, match.start),
            style: _styleMap['default']?.merge(style),
          ),
        );
      }

      final String matchedText = match.group(0)!;
      String? styleKey;

      // 🟢 Comments
      if (matchedText.startsWith('//') || matchedText.startsWith('/*')) {
        styleKey = 'comment';
      }
      // 🟠 Strings
      else if (matchedText.startsWith('"') || matchedText.startsWith("'")) {
        styleKey = 'string';
      }
      // 🟣 Annotation (@override)
      else if (matchedText.startsWith('@')) {
        styleKey = 'annotation';
      }
      // 🔵 Numbers
      else if (RegExp(r'^\d').hasMatch(matchedText)) {
        styleKey = 'number';
      }
      // ⚪ Operators
      else if (_operators.contains(matchedText)) {
        styleKey = 'operator';
      }
      // ⚪ Punctuation
      else if (_punctuation.contains(matchedText)) {
        styleKey = 'punctuation';
      }
      // 🧠 Words
      else if (_wordRegExp.hasMatch(matchedText)) {
        if (dartControlKeywords.contains(matchedText)) {
          styleKey = 'keyword';
        } else if (dartModifiers.contains(matchedText)) {
          styleKey = 'modifier';
        } else if (dartConstants.contains(matchedText)) {
          styleKey = 'boolean';
        } else if (dartTypes.contains(matchedText)) {
          styleKey = 'type';
        } else if (flutterCoreClasses.contains(matchedText)) {
          styleKey = 'class';
        }
        // After class keyword → class name
        else if (previousWord == 'class' ||
            previousWord == 'enum' ||
            previousWord == 'mixin') {
          styleKey = 'class';
        }
        // After extends / implements
        else if (previousWord == 'extends' ||
            previousWord == 'implements' ||
            previousWord == 'with') {
          styleKey = 'class';
        }
        // Detect function (if next char is '(')
        else if (match.end < currentText.length) {
          final nextChar = currentText.substring(match.end).trimLeft();

          if (nextChar.startsWith('(')) {
            styleKey = 'function';
          }
        }

        // Capital letter = likely class
        if (styleKey == null && RegExp(r'^[A-Z]').hasMatch(matchedText)) {
          styleKey = 'type';
        }

        previousWord = matchedText;
      }

      final TextStyle? matchedStyle = _styleMap[styleKey ?? 'default']?.merge(
        style,
      );

      children.add(TextSpan(text: matchedText, style: matchedStyle));

      lastMatchEnd = match.end;

      if (styleKey == null || !_wordRegExp.hasMatch(matchedText)) {
        if (matchedText.trim().isNotEmpty && styleKey != 'comment') {
          previousWord = null;
        }
      }
    }

    if (lastMatchEnd < currentText.length) {
      children.add(
        TextSpan(
          text: currentText.substring(lastMatchEnd),
          style: _styleMap['default']?.merge(style),
        ),
      );
    }

    return TextSpan(children: children, style: style);
  }
}
