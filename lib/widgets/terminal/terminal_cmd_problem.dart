// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:laravelide/models/problem_terminal_model.dart';
// import 'package:laravelide/services/flutter/os_support/os_utils_flutter.dart';
// import 'package:laravelide/services/flutter/terminal_cmd.dart';

// class TerminalCmdProblem extends StatefulWidget {
//   const TerminalCmdProblem({super.key, required this.projectPath});

//   final String projectPath;

//   @override
//   State<TerminalCmdProblem> createState() => _TerminalCmdProblemState();
// }

// class _TerminalCmdProblemState extends State<TerminalCmdProblem> {
//   List<String> logLines = [];
//   List<ProblemTerminalModel> issues = [];
//   bool isLoading = false;

//   CommandSubscription? _subscription;

//   @override
//   void initState() {
//     super.initState();
//     startLogStream();
//   }

//   Future<void> startLogStream() async {
//     setState(() {
//       logLines.clear();
//       issues.clear();
//       isLoading = true;
//     });

//     _subscription = await TerminalCmd.projectAnalyzeStream(
//       parentDir: widget.projectPath,
//       onLog: (msg) {
//         if (!mounted) return;

//         setState(() {
//           logLines.add(msg);

//           final parsed = parseIssue(msg);
//           if (parsed != null) issues.add(parsed);
//         });
//       },
//       onComplete: () {
//         if (!mounted) return;

//         setState(() => isLoading = false);
//       },
//     );
//   }

//   ProblemTerminalModel? parseIssue(String line) {
//     if (line.startsWith("[ERR]")) return null;
//     if (!line.contains(" - ")) return null;

//     final parts = line.split(" - ");
//     if (parts.length < 4) return null;

//     String type = parts[0].trim();

//     String message = parts.sublist(1, parts.length - 2).join(" - ").trim();

//     String fileAndPosition = parts[parts.length - 2].trim();
//     String rule = parts.last.trim();

//     final fileParts = fileAndPosition.split(":");
//     if (fileParts.length < 3) return null;

//     String file = fileParts[0].replaceAll("\\", "/").trim();
//     int lineNum = int.tryParse(fileParts[1]) ?? 0;
//     int colNum = int.tryParse(fileParts[2]) ?? 0;

//     return ProblemTerminalModel(
//       type: type,
//       message: message,
//       file: file,
//       line: lineNum,
//       column: colNum,
//       rule: rule,
//     );
//   }

//   @override
//   void dispose() {
//     _subscription?.cancel();
//     super.dispose();
//   }

//   Color _getTypeColor(String type) {
//     switch (type.toLowerCase()) {
//       case "error":
//         return Colors.redAccent;
//       case "warning":
//         return Colors.amberAccent;
//       case "info":
//       default:
//         return Colors.lightBlueAccent;
//     }
//   }

//   IconData _getTypeIcon(String type) {
//     switch (type.toLowerCase()) {
//       case "error":
//         return Icons.error;
//       case "warning":
//         return Icons.warning;
//       default:
//         return Icons.info;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     Map<String, List<ProblemTerminalModel>> grouped = {};

//     for (final issue in issues) {
//       grouped.putIfAbsent(issue.file, () => []);
//       grouped[issue.file]!.add(issue);
//     }

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: issues.isEmpty
//             ? Center(
//                 child: Text(
//                   isLoading ? "Analyzing project..." : "No problems found",
//                   style: TextStyle(color: Colors.white70, fontSize: 16),
//                 ),
//               )
//             : ListView.builder(
//                 itemCount: grouped.keys.length,
//                 itemBuilder: (context, index) {
//                   final file = grouped.keys.elementAt(index);
//                   final filename = grouped.keys.elementAt(index).split("/");
//                   final fileIssues = grouped[file]!;

//                   return Theme(
//                     data: Theme.of(
//                       context,
//                     ).copyWith(dividerColor: Colors.grey.shade800),
//                     child: ExpansionTile(
//                       collapsedIconColor: Colors.white70,
//                       initiallyExpanded: true,
//                       iconColor: Colors.white,
//                       title: Text(
//                         filename.last,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       children: fileIssues.map((issue) {
//                         return ListTile(
//                           leading: Icon(
//                             _getTypeIcon(issue.type),
//                             color: _getTypeColor(issue.type),
//                           ),
//                           title: Text(
//                             issue.message,
//                             style: TextStyle(
//                               color: _getTypeColor(issue.type),
//                               fontSize: 14,
//                             ),
//                           ),
//                           subtitle: Text(
//                             "Line ${issue.line}, Column ${issue.column}",
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12,
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   );
//                 },
//               ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:laravelide/models/problem_terminal_model.dart';
import 'package:laravelide/services/flutter/os_support/os_utils_flutter.dart';
import 'package:laravelide/services/flutter/terminal_cmd.dart';

// Optimized TerminalCmdProblem:
// - Parses logs in an isolate (compute)
// - Throttles UI updates (150ms)
// - Maintains grouped issues incrementally (no grouping inside build)
// - Keeps a cap on stored logs/issues to avoid memory blowup

class TerminalCmdProblem extends StatefulWidget {
  const TerminalCmdProblem({super.key, required this.projectPath});

  final String projectPath;

  @override
  State<TerminalCmdProblem> createState() => _TerminalCmdProblemState();
}

class _TerminalCmdProblemState extends State<TerminalCmdProblem> {
  // Raw log lines (capped)
  final List<String> _logLines = [];

  // Flat list of issues (capped)
  final List<ProblemTerminalModel> _issues = [];

  // Grouped issues stored incrementally; keys list snapshot used for UI
  final Map<String, List<ProblemTerminalModel>> _groupedIssues = {};
  List<String> _groupedKeysSnapshot = [];

  bool _isLoading = false;

  CommandSubscription? _subscription;

  Timer? _throttleTimer;
  static const Duration _throttleDuration = Duration(milliseconds: 150);

  // caps to avoid unbounded memory usage
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

        // Add raw log (capped)
        _addLogLineInternal(msg);

        // Parse in isolate and convert back to a ProblemTerminalModel on main isolate
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

        // Throttle UI updates: rebuild at most ~6-10 times/sec
        _scheduleThrottledRefresh();
      },
      onComplete: () {
        if (!mounted) return;
        _isLoading = false;
        // Ensure final UI update
        _scheduleThrottledRefresh(force: true);
      },
    );
  }

  // Internal: add log line and cap list size
  void _addLogLineInternal(String msg) {
    _logLines.add(msg);
    if (_logLines.length > _maxLogLines) {
      _logLines.removeRange(0, _logLines.length - _maxLogLines);
    }
  }

  // Internal: add issue, maintain grouped map and cap
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
          // Snapshot keys for stable ListView building
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

  // ---------- UI helpers ----------
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
        child: _groupedKeysSnapshot.isEmpty
            ? Center(
                child: Text(
                  _isLoading ? 'Analyzing project...' : 'No problems found',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
            : ListView.builder(
                itemCount: _groupedKeysSnapshot.length,
                itemBuilder: (context, index) {
                  final file = _groupedKeysSnapshot[index];
                  final filenameParts = file.split('/');
                  final fileIssues = _groupedIssues[file] ?? [];

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

// ---------- Isolate-safe parser ----------
// Returns a Map<String, dynamic> that can be sent back across isolates
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
