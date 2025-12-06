import 'package:flutter/material.dart';
import 'package:laravelide/services/flutter/terminal_cmd.dart';

class TerminalLogStore {
  static final List<String> logs = [];
  static void add(String msg) => logs.add(msg);
  static void clear() => logs.clear();
}

class TerminalCmdDebug extends StatefulWidget {
  final String projectPath;
  const TerminalCmdDebug({super.key, required this.projectPath});
  @override
  State<TerminalCmdDebug> createState() => _TerminalCmdDebugState();
}

class _TerminalCmdDebugState extends State<TerminalCmdDebug> {
  final ScrollController _controller = ScrollController();

  // void _safeScrollToEnd() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!_controller.hasClients) return;
  //     try {
  //       _controller.jumpTo(_controller.position.maxScrollExtent);
  //     } catch (_) {}
  //   });
  // }

  List<TextSpan> _buildSpans(String text) {
    final ansiPattern = RegExp('\u001b\\[([\\d;]+)m');

    final spans = <TextSpan>[];
    int lastIndex = 0;

    TextStyle currentStyle = const TextStyle(
      color: Color(0xFFCCCCCC),
      fontFamily: 'monospace',
      fontSize: 13,
    );

    for (final match in ansiPattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: currentStyle,
          ),
        );
      }

      final codeString = match.group(1);
      if (codeString != null) {
        final codes = codeString.split(';').map(int.tryParse);
        for (final code in codes) {
          if (code != null) {
            currentStyle = _applyAnsiCode(currentStyle, code);
          }
        }
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: currentStyle));
    }

    return spans;
  }

  TextStyle _applyAnsiCode(TextStyle style, int code) {
    switch (code) {
      case 0:
        return style.copyWith(color: const Color(0xFFCCCCCC));
      case 30:
        return style.copyWith(color: Colors.black);
      case 31:
        return style.copyWith(color: Colors.redAccent);
      case 32:
        return style.copyWith(color: Colors.greenAccent);
      case 33:
        return style.copyWith(color: Colors.yellowAccent);
      case 34:
        return style.copyWith(color: Colors.blueAccent);
      case 35:
        return style.copyWith(color: Colors.purpleAccent);
      case 36:
        return style.copyWith(color: Colors.cyanAccent);
      case 37:
        return style.copyWith(color: Colors.white);
      case 90:
        return style.copyWith(color: Colors.grey);
      default:
        return style;
    }
  }

  // void _runProject() {
  //   TerminalLogStore.clear();

  //   final unwantedPatterns = [
  //     "Flutter run key commands.",
  //     "r Hot reload.",
  //     "R Hot restart.",
  //     "h List all available interactive commands.",
  //     "d Detach (terminate",
  //     "c Clear the screen",
  //     "q Quit (terminate",
  //   ];

  //   TerminalCmd.projectRunStream(
  //     parentDir: widget.projectPath,
  //     onLog: (line) {
  //       if (unwantedPatterns.any((p) => line.trim().startsWith(p))) {
  //         return;
  //       }

  //       TerminalLogStore.add(line);
  //       if (mounted) setState(() {});
  //       _safeScrollToEnd();
  //     },
  //     onComplete: () {},
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Container(
        color: Colors.black,
        child: ListView.builder(
          controller: _controller,
          padding: const EdgeInsets.all(8),
          shrinkWrap: true,
          itemCount: TerminalLogStore.logs.length,
          itemBuilder: (context, index) {
            return SelectableText.rich(
              TextSpan(children: _buildSpans(TerminalLogStore.logs[index])),
            );
          },
        ),
      ),
    );
  }
}
