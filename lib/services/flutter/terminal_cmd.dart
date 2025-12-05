import 'package:laravelide/services/flutter/os_support/os_utils_flutter.dart';

class TerminalCmd {
  static Future<CommandSubscription> projectAnalyzeStream({
    required String parentDir,
    required Function(String) onLog,
    required Function() onComplete,
  }) async {
    return OsUtilsFlutter.streamCommand(
      command: "flutter",
      args: ["analyze"],
      workingDirectory: parentDir,
      onLine: onLog,
      onComplete: (_) => onComplete(),
    );
  }

  static Future<CommandSubscription> projectRunStream({
    required String parentDir,
    required Function(String) onLog,
    required Function() onComplete,
  }) async {
    return OsUtilsFlutter.streamCommand(
      command: "flutter",
      args: ["run", "-d", "chrome"],
      workingDirectory: parentDir,
      onLine: onLog,
      onComplete: (_) => onComplete(),
    );
  }

  static Future<CommandSubscription> addDependencyStream({
    required String dependencyName,
    required String parentDir,
    required Function(String) onLog,
    required Function() onComplete,
  }) async {
    return OsUtilsFlutter.streamCommand(
      command: "flutter",
      args: ["pub", "add", dependencyName],
      workingDirectory: parentDir,
      onLine: onLog,
      onComplete: (_) => onComplete(),
    );
  }
}
