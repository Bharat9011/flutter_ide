import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:laravelide/models/problem_terminal_model.dart';
import 'package:laravelide/services/flutter/os_support/os_utils_flutter.dart';
import 'package:laravelide/services/flutter/terminal_cmd.dart';

class TerminalCmdProblem extends StatefulWidget {
  const TerminalCmdProblem({super.key, required this.projectPath});

  final String projectPath;

  @override
  State<TerminalCmdProblem> createState() => _TerminalCmdProblemState();
}

class _TerminalCmdProblemState extends State<TerminalCmdProblem> {
  final List<String> _logLines = [];

  final List<ProblemTerminalModel> _issues = [];

  final Map<String, List<ProblemTerminalModel>> _groupedIssues = {};
  List<String> _groupedKeysSnapshot = [];

  bool _isLoading = false;

  CommandSubscription? _subscription;

  Timer? _throttleTimer;
  static const Duration _throttleDuration = Duration(milliseconds: 150);

  static const int _maxLogLines = 2000;
  static const int _maxIssues = 2000;

  @override
  void initState() {
    super.initState();
    _startLogStream();
  }

  Future<void> _startLogStream() async {
    setState(() {
      _logLines.clear();
      _issues.clear();
      _groupedIssues.clear();
      _groupedKeysSnapshot = [];
      _isLoading = true;
    });

    _subscription = await TerminalCmd.projectAnalyzeStream(
      parentDir: widget.projectPath,
      onLog: (msg) async {
        if (!mounted) return;

        _addLogLineInternal(msg);

        final Map<String, dynamic>? parsedMap = await compute(
          _parseIssueIsolate,
          msg,
        );
        if (parsedMap != null) {
          final issue = ProblemTerminalModel(
            type: parsedMap['type'] ?? 'info',
            message: parsedMap['message'] ?? '',
            file: parsedMap['file'] ?? '',
            line: parsedMap['line'] ?? 0,
            column: parsedMap['column'] ?? 0,
            rule: parsedMap['rule'] ?? '',
          );

          _addIssueInternal(issue);
        }

        _scheduleThrottledRefresh();
      },
      onComplete: () {
        if (!mounted) return;
        _isLoading = false;
        _scheduleThrottledRefresh(force: true);
      },
    );
  }

  void _addLogLineInternal(String msg) {
    _logLines.add(msg);
    if (_logLines.length > _maxLogLines) {
      _logLines.removeRange(0, _logLines.length - _maxLogLines);
    }
  }

  void _addIssueInternal(ProblemTerminalModel issue) {
    _issues.add(issue);
    if (_issues.length > _maxIssues) {
      _issues.removeRange(0, _issues.length - _maxIssues);
    }

    final fileKey = issue.file;
    final list = _groupedIssues.putIfAbsent(fileKey, () => []);
    list.add(issue);
  }

  void _scheduleThrottledRefresh({bool force = false}) {
    if (force) {
      if (mounted) {
        setState(() {
          _groupedKeysSnapshot = List<String>.from(_groupedIssues.keys);
        });
      }
      return;
    }

    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      _throttleTimer = Timer(_throttleDuration, () {
        if (!mounted) return;
        setState(() {
          _groupedKeysSnapshot = List<String>.from(_groupedIssues.keys);
        });
      });
    }
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'error':
        return Colors.redAccent;
      case 'warning':
        return Colors.amberAccent;
      case 'info':
      default:
        return Colors.lightBlueAccent;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView.builder(
          itemCount: _groupedKeysSnapshot.length,
          itemBuilder: (context, index) {
            final file = _groupedKeysSnapshot[index];
            final filenameParts = file.split('/');
            final fileIssues = _groupedIssues[file] ?? [];

            if (_groupedKeysSnapshot.isEmpty) {
              return Expanded(
                child: Center(
                  child: Text(
                    'No problems found',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              );
            }

            return Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.grey.shade800),
              child: ExpansionTile(
                collapsedIconColor: Colors.white70,
                initiallyExpanded: true,
                iconColor: Colors.white,
                title: Text(
                  filenameParts.isNotEmpty ? filenameParts.last : file,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: fileIssues.map((issue) {
                  return ListTile(
                    leading: Icon(
                      _getTypeIcon(issue.type),
                      color: _getTypeColor(issue.type),
                    ),
                    title: Text(
                      issue.message,
                      style: TextStyle(
                        color: _getTypeColor(issue.type),
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Line ${issue.line}, Column ${issue.column}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

Map<String, dynamic>? _parseIssueIsolate(String line) {
  try {
    if (line.startsWith('[ERR]')) return null;
    if (!line.contains(' - ')) return null;

    final parts = line.split(' - ');
    if (parts.length < 4) return null;

    final type = parts[0].trim();
    final message = parts.sublist(1, parts.length - 2).join(' - ').trim();
    final fileAndPosition = parts[parts.length - 2].trim();
    final rule = parts.last.trim();

    final fileParts = fileAndPosition.split(':');
    if (fileParts.length < 3) return null;

    final file = fileParts[0].replaceAll('\\', '/').trim();
    final lineNum = int.tryParse(fileParts[1]) ?? 0;
    final colNum = int.tryParse(fileParts[2]) ?? 0;

    return {
      'type': type,
      'message': message,
      'file': file,
      'line': lineNum,
      'column': colNum,
      'rule': rule,
    };
  } catch (_) {
    return null;
  }
}
