import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laravelide/GetProvider/debug_log_getx_controller.dart';

class TerminalCmdDebug extends StatefulWidget {
  final String projectPath;
  const TerminalCmdDebug({super.key, required this.projectPath});
  @override
  State<TerminalCmdDebug> createState() => _TerminalCmdDebugState();
}

class _TerminalCmdDebugState extends State<TerminalCmdDebug> {
  final ScrollController _controller = ScrollController();

  final log = Get.put(DebugLogGetxController());

  void _safeScrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      try {
        _controller.jumpTo(_controller.position.maxScrollExtent);
      } catch (_) {}
    });
  }

  @override
  void initState() {
    _safeScrollToEnd();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,

        child: Obx(() {
          return SelectionArea(
            child: ListView.builder(
              controller: _controller,
              padding: const EdgeInsets.all(8),
              shrinkWrap: false,
              itemCount: log.debugLogs.length,
              itemBuilder: (context, index) {
                return Text.rich(
                  TextSpan(children: _buildSpans(log.debugLogs[index])),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
