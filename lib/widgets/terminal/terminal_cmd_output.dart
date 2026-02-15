import 'package:flutter/material.dart';

class TerminalOutputLogStore {
  static final List<String> logs = [];
  static void add(String msg) => logs.add(msg);
  static void clear() => logs.clear();
}

class TerminalCmdOutput extends StatefulWidget {
  TerminalCmdOutput({super.key, required this.projectPath});

  String projectPath;

  @override
  State<TerminalCmdOutput> createState() => _TerminalCmdOutputState();
}

class _TerminalCmdOutputState extends State<TerminalCmdOutput> {
  final ScrollController _controller = ScrollController();

  void _safeScrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      try {
        _controller.jumpTo(_controller.position.maxScrollExtent);
      } catch (_) {}
    });
  }

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
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: currentStyle));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: ListView.builder(
          controller: _controller,
          padding: const EdgeInsets.all(8),
          shrinkWrap: true,
          itemCount: TerminalOutputLogStore.logs.length,
          itemBuilder: (context, index) {
            return SelectableText.rich(
              TextSpan(
                children: _buildSpans(TerminalOutputLogStore.logs[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}
