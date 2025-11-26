import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TerminalCmdTerminal extends StatefulWidget {
  final String projectPath;

  const TerminalCmdTerminal({super.key, required this.projectPath});

  static List<_SavedLine> _sessionHistory = [];
  static String? _lastDirectory;

  static List<String> commandHistory = [];

  @override
  State<TerminalCmdTerminal> createState() => _TerminalCmdTerminalState();
}

class _TerminalCmdTerminalState extends State<TerminalCmdTerminal> {
  final ScrollController _scrollController = ScrollController();
  final List<_TerminalLine> _lines = [];

  bool _isRunning = false;
  String _currentDirectory = "";

  Timer? _loadingTimer;
  Timer? _loadingAnimTimer;
  bool _isShowingLoading = false;
  int _loadingFrame = 0;

  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();

    _currentDirectory =
        TerminalCmdTerminal._lastDirectory ?? widget.projectPath;
    TerminalCmdTerminal._lastDirectory = _currentDirectory;

    _restoreSession();
  }

  void _restoreSession() {
    _lines.clear();

    for (final saved in TerminalCmdTerminal._sessionHistory) {
      final line = _TerminalLine(prompt: "$_currentDirectory> ");
      for (final out in saved.outputs) {
        line.outputs.add(OutputItem(out.text, out.type));
      }
      _lines.add(line);
    }

    _addPrompt();
  }

  void _syncHistory() {
    TerminalCmdTerminal._sessionHistory = _lines
        .where((l) => l.outputs.isNotEmpty)
        .map(
          (l) => _SavedLine(
            l.outputs.map((o) => OutputItem(o.text, o.type)).toList(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _loadingTimer?.cancel();
    _loadingAnimTimer?.cancel();

    for (final l in _lines) {
      l.controller.dispose();
      l.focusNode.dispose();
    }

    super.dispose();
  }

  void _addPrompt() {
    final line = _TerminalLine(prompt: "$_currentDirectory> ");
    _lines.add(line);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      line.focusNode.requestFocus();
      _scrollToBottom();
    });

    setState(() {});
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _runCommand(_TerminalLine line, String cmd) async {
    if (_isRunning) return;

    final command = cmd.trim();
    if (command.isEmpty) {
      _addPrompt();
      return;
    }

    TerminalCmdTerminal.commandHistory.add(command);
    _historyIndex = TerminalCmdTerminal.commandHistory.length;

    final isFlutterCommand = command.startsWith("flutter ");

    line.addOutput(
      "${line.prompt}$command",
      isFlutterCommand ? LineType.flutter : LineType.command,
    );
    _syncHistory();
    setState(() {});

    _isRunning = true;

    try {
      if (command == "cls" || command == "clear") {
        _lines.clear();
        TerminalCmdTerminal._sessionHistory = [];
        _isRunning = false;
        _addPrompt();
        return;
      }

      if (command.startsWith("cd")) {
        await _changeDirectory(line, command);
      } else {
        await _executeCommand(
          line,
          command,
          isFlutterCommand: isFlutterCommand,
        );
      }
    } catch (e) {
      line.addOutput("Error: $e", LineType.error);
    }

    _isRunning = false;
    _syncHistory();
    _addPrompt();
  }

  Future<void> _changeDirectory(_TerminalLine line, String cmd) async {
    final parts = cmd.split(RegExp(r"\s+"));
    if (parts.length == 1) {
      line.addOutput(_currentDirectory, LineType.info);
      _syncHistory();
      return;
    }

    String path = parts.sublist(1).join(" ").trim();

    if (path == "..") {
      path = Directory(_currentDirectory).parent.path;
    } else if (!path.contains(":") && !path.startsWith("/")) {
      path = "$_currentDirectory${Platform.pathSeparator}$path";
    }

    final dir = Directory(path);

    if (await dir.exists()) {
      _currentDirectory = dir.path;
      TerminalCmdTerminal._lastDirectory = _currentDirectory;
      line.addOutput("Directory changed: $_currentDirectory", LineType.info);
    } else {
      line.addOutput(
        "The system cannot find the path specified.",
        LineType.error,
      );
    }

    _syncHistory();
  }

  void _showLoading(_TerminalLine line) {
    if (_isShowingLoading) return;

    _isShowingLoading = true;
    _loadingFrame = 0;

    line.addOutput(_loadingText(), LineType.info);
    _syncHistory();

    _loadingAnimTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!_isShowingLoading) return;

      if (line.outputs.isNotEmpty &&
          line.outputs.last.text.startsWith("[loading")) {
        line.outputs.removeLast();
      }

      line.outputs.add(OutputItem(_loadingText(), LineType.info));
      _loadingFrame = (_loadingFrame + 1) % 4;

      _syncHistory();
      setState(() {});
      _scrollToBottom();
    });

    setState(() {});
  }

  void _hideLoading(_TerminalLine line) {
    if (!_isShowingLoading) return;

    _loadingAnimTimer?.cancel();

    if (line.outputs.isNotEmpty &&
        line.outputs.last.text.startsWith("[loading")) {
      line.outputs.removeLast();
    }

    _isShowingLoading = false;
    _syncHistory();
    setState(() {});
  }

  String _loadingText() {
    switch (_loadingFrame) {
      case 1:
        return "[loading .]";
      case 2:
        return "[loading ..]";
      case 3:
        return "[loading ...]";
      default:
        return "[loading   ]";
    }
  }

  Future<void> _executeCommand(
    _TerminalLine line,
    String cmd, {
    bool isFlutterCommand = false,
  }) async {
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      line.addOutput(
        "Error: Process execution is only supported on desktop platforms.",
        LineType.error,
      );
      _syncHistory();
      return;
    }

    final executable = Platform.isWindows ? "cmd.exe" : "/bin/bash";
    final args = Platform.isWindows ? ["/c", cmd] : ["-c", cmd];

    _loadingTimer?.cancel();
    _hideLoading(line);
    _loadingTimer = Timer(const Duration(milliseconds: 150), () {
      _showLoading(line);
    });

    final process = await Process.start(
      executable,
      args,
      workingDirectory: _currentDirectory,
      runInShell: true,
    );

    void handleLine(String text, bool isError) {
      _loadingTimer?.cancel();
      _hideLoading(line);

      if (text.trim().isNotEmpty) {
        final type = isError
            ? LineType.error
            : (isFlutterCommand ? LineType.flutter : LineType.output);

        line.addOutput(text.trimRight(), type);
        _syncHistory();
        setState(() {});
        _scrollToBottom();
      }

      _loadingTimer = Timer(const Duration(milliseconds: 150), () {
        _showLoading(line);
      });
    }

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((lineText) => handleLine(lineText, false));

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((lineText) => handleLine(lineText, true));

    await process.exitCode;

    _loadingTimer?.cancel();
    _hideLoading(line);
  }

  void _handleHistoryNavigation(_TerminalLine line, {required bool up}) {
    if (TerminalCmdTerminal.commandHistory.isEmpty) return;

    setState(() {
      if (up) {
        if (_historyIndex > 0) {
          _historyIndex--;
        }
      } else {
        if (_historyIndex < TerminalCmdTerminal.commandHistory.length - 1) {
          _historyIndex++;
        } else {
          _historyIndex = TerminalCmdTerminal.commandHistory.length;
          line.controller.text = "";
          return;
        }
      }

      line.controller.text = TerminalCmdTerminal.commandHistory[_historyIndex];
      line.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: line.controller.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: _lines.length,
          itemBuilder: (context, index) {
            final line = _lines[index];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (line.isPrompt)
                  Row(
                    children: [
                      Text(
                        line.prompt,
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontFamily: "Courier",
                        ),
                      ),

                      Expanded(
                        child: Focus(
                          onKey: (FocusNode node, RawKeyEvent event) {
                            if (event is RawKeyDownEvent) {
                              final key = event.logicalKey;
                              if (key == LogicalKeyboardKey.arrowUp) {
                                _handleHistoryNavigation(line, up: true);
                                return KeyEventResult.handled;
                              } else if (key == LogicalKeyboardKey.arrowDown) {
                                _handleHistoryNavigation(line, up: false);
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            focusNode: line.focusNode,
                            controller: line.controller,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: "Courier",
                            ),
                            cursorColor: Colors.white,
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (cmd) => _runCommand(line, cmd),
                          ),
                        ),
                      ),
                    ],
                  ),

                for (var out in line.outputs)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      out.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Courier",
                        color: _colorForType(out.type),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _colorForType(LineType type) {
    switch (type) {
      case LineType.error:
        return Colors.redAccent;
      case LineType.info:
        return Colors.blueAccent;
      case LineType.flutter:
        return Colors.cyanAccent;
      case LineType.command:
        return Colors.greenAccent;
      case LineType.output:
        return Colors.greenAccent;
    }
  }
}

class _TerminalLine {
  final String prompt;
  final TextEditingController controller = TextEditingController();

  final FocusNode focusNode = FocusNode();

  final List<OutputItem> outputs = [];

  _TerminalLine({required this.prompt});

  bool get isPrompt => outputs.isEmpty;

  void addOutput(String text, LineType type) {
    outputs.add(OutputItem(text, type));
  }
}

class OutputItem {
  final String text;
  final LineType type;

  OutputItem(this.text, this.type);
}

enum LineType { command, output, info, error, flutter }

class _SavedLine {
  final List<OutputItem> outputs;

  _SavedLine(this.outputs);
}
