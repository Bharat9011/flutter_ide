// import 'dart:io';

// class OSUtils {
//   static bool isWindows() => Platform.isWindows;
//   static bool isLinux() => Platform.isLinux;
//   static bool isMac() => Platform.isMacOS;

//   static Future<ProcessResult> runCommand(String command, List<String> args, {String? workingDirectory}) async {
//     return await Process.run(
//       command,
//       args,
//       workingDirectory: workingDirectory,
//       runInShell: true,
//     );
//   }
// }


import 'dart:io';
import 'dart:convert';

class OSUtils {
  static bool isWindows() => Platform.isWindows;
  static bool isLinux() => Platform.isLinux;
  static bool isMac() => Platform.isMacOS;

  /// Runs a command and returns full output when complete
  static Future<ProcessResult> runCommand(String command, List<String> args, {String? workingDirectory}) async {
    return await Process.run(
      command,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
  }

  /// ✅ Stream command output in real time (for terminal logs)
  static Future<void> streamCommand({
    required String command,
    required List<String> args,
    String? workingDirectory,
    required Function(String line) onLine,
    required Function(int exitCode) onComplete,
  }) async {
    final process = await Process.start(
      command,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(onLine);

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => onLine("[ERR] $line"));

    process.exitCode.then(onComplete);
  }
}
