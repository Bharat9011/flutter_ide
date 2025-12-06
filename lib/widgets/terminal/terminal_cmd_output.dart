import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laravelide/GetProvider/is_completed_getx_provider.dart';
import 'package:laravelide/GetProvider/new_project_getx_provider.dart';
import 'package:laravelide/services/flutter/create_project_utils.dart';
import 'package:laravelide/services/flutter/terminal_cmd.dart';

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

  void _createProject() {
    var newProjectController = Get.put(NewProjectGetxProvider());

    if (newProjectController.isCreated.value) {
      if (newProjectController.isCreated.value) {
        if (newProjectController.platform.value == "Flutter") {
          if (newProjectController.projectType.value == "Flutter App") {
            CreateProjectUtils.createProjectStream(
              parentDir: newProjectController.path.value,
              projectName: newProjectController.name.value,
              onLog: (line) {
                TerminalOutputLogStore.add(line);
                if (mounted) setState(() {});
                _safeScrollToEnd();
              },
              onComplete: () {
                var checkCompleted = Get.put(IsCompletedGetxProvider());

                checkCompleted.setCompleted(true);
              },
            );
          }
          if (newProjectController.projectType.value == "Flutter Module") {}
          if (newProjectController.projectType.value == "Flutter Plugin") {}
          if (newProjectController.projectType.value == "Flutter Package") {}
          if (newProjectController.projectType.value == "Flutter Skeleton") {}
        }
        if (newProjectController.platform.value == "Dart") {
          if (newProjectController.projectType.value == "Dart Console App") {}
          if (newProjectController.projectType.value == "Dart Package") {}
          if (newProjectController.projectType.value ==
              "Dart Server (shelf)") {}
          if (newProjectController.projectType.value == "Dart Web App") {}
          if (newProjectController.projectType.value == "Dart CLI") {}
        }
      }
    }

    newProjectController.markCreated(false);
  }

  // void _runProject() {
  //   TerminalOutputLogStore.clear();

  //   TerminalCmd.addDependencyStream(
  //     dependencyName: "flutter_easyloading",
  //     parentDir: widget.projectPath,
  //     onLog: (line) {
  //       TerminalOutputLogStore.add(line);
  //       if (mounted) setState(() {});
  //       _safeScrollToEnd();
  //     },
  //     onComplete: () {},
  //   );
  // }

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
    super.initState();
    _createProject();
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
