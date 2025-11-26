import 'package:flutter/material.dart';
import 'package:laravelide/services/flutter/terminal_cmd.dart';
// import 'package:laravelide/widgets/terminal/debug_view.dart'; // Replaced with direct view for demo
import 'package:xterm/ui.dart';

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

  void _safeScrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      try {
        _controller.jumpTo(_controller.position.maxScrollExtent);
      } catch (_) {}
    });
  }

  // --- NEW: ANSI Parsing Logic (The VS Code Way) ---
  List<TextSpan> _buildSpans(String text) {
    // FIXED: Removed 'r' to allow \u001b to be read as the ESC character
    final ansiPattern = RegExp('\u001b\\[([\\d;]+)m');

    final spans = <TextSpan>[];
    int lastIndex = 0;

    // Default style
    TextStyle currentStyle = const TextStyle(
      color: Color(0xFFCCCCCC),
      fontFamily: 'monospace',
      fontSize: 13,
    );

    for (final match in ansiPattern.allMatches(text)) {
      // 1. Add text before the code
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: currentStyle,
          ),
        );
      }

      // 2. Process the color code
      final codeString = match.group(1);
      if (codeString != null) {
        // Handle composite codes like "1;31" (Bold Red)
        final codes = codeString.split(';').map(int.tryParse);
        for (final code in codes) {
          if (code != null) {
            currentStyle = _applyAnsiCode(currentStyle, code);
          }
        }
      }

      lastIndex = match.end;
    }

    // 3. Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: currentStyle));
    }

    return spans;
  }

  // Helper: Maps ANSI numbers to Flutter Colors
  TextStyle _applyAnsiCode(TextStyle style, int code) {
    switch (code) {
      case 0:
        return style.copyWith(color: const Color(0xFFCCCCCC)); // Reset
      case 30:
        return style.copyWith(color: Colors.black);
      case 31:
        return style.copyWith(color: Colors.redAccent); // Red (Error)
      case 32:
        return style.copyWith(color: Colors.greenAccent); // Green (Success)
      case 33:
        return style.copyWith(color: Colors.yellowAccent); // Yellow (Warning)
      case 34:
        return style.copyWith(color: Colors.blueAccent); // Blue
      case 35:
        return style.copyWith(color: Colors.purpleAccent); // Magenta
      case 36:
        return style.copyWith(color: Colors.cyanAccent); // Cyan
      case 37:
        return style.copyWith(color: Colors.white);
      case 90:
        return style.copyWith(color: Colors.grey); // Bright Black
      default:
        return style;
    }
  }

  void _runProject() {
    // Optional: Clear previous logs on new run
    TerminalLogStore.clear();

    TerminalCmd.projectRunStream(
      parentDir: widget.projectPath,
      onLog: (line) {
        TerminalLogStore.add(line);
        if (mounted) setState(() {});
        _safeScrollToEnd();
      },
      onComplete: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // VS Code Dark Theme background
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: _runProject,
              child: const Text("Run Project"),
            ),
          ),
          Expanded(
            // We use ListView.builder for performance with large logs
            child: ListView.builder(
              controller: _controller,
              padding: const EdgeInsets.all(8),
              itemCount: TerminalLogStore.logs.length,
              itemBuilder: (context, index) {
                // Here we apply the new parser
                return SelectableText.rich(
                  TextSpan(children: _buildSpans(TerminalLogStore.logs[index])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
