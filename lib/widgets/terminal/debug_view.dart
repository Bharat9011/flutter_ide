import 'package:flutter/material.dart';
import 'package:laravelide/parses/terminal/ansi_parser.dart';
import 'package:laravelide/parses/terminal/detect_block_color.dart';

class DebugView extends StatefulWidget {
  final List<String> logs;

  const DebugView({super.key, required this.logs});

  @override
  State<DebugView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<DebugView> {
  final ScrollController controller = ScrollController();

  @override
  void didUpdateWidget(covariant DebugView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) return;
      controller.jumpTo(controller.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool inError = false;
    bool inWarn = false;

    final spans = <TextSpan>[];

    for (final raw in widget.logs) {
      final line = raw;
      final lower = line.toLowerCase();

      if (lower.contains("exception") ||
          lower.contains("error") ||
          lower.contains("failed")) {
        inError = true;
        inWarn = false;
      }

      if (lower.contains("warning")) {
        inWarn = true;
        inError = false;
      }

      if (lower.isEmpty) {
        inError = false;
        inWarn = false;
      }

      final color = detectBlockColor(line, inError, inWarn);

      spans.add(
        TextSpan(
          children: [
            parseAnsi(line), // parse ANSI inside the line
            const TextSpan(text: "\n"),
          ],
          style: TextStyle(color: color, fontSize: 13),
        ),
      );
    }
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(8),
        child: SelectableText.rich(TextSpan(children: spans)),
      ),
    );
  }
}
