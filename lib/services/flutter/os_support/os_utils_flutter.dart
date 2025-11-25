import 'dart:async';
import 'dart:convert';
import 'dart:io';

class CommandSubscription {
  StreamSubscription stdoutSub;
  StreamSubscription stderrSub;

  CommandSubscription(this.stdoutSub, this.stderrSub);

  void cancel() {
    stdoutSub.cancel();
    stderrSub.cancel();
  }
}

class OsUtilsFlutter {
  static Future<CommandSubscription> streamCommand({
    required String command,
    required List<String> args,
    String? workingDirectory,
    required Function(String) onLine,
    required Function(int exitCode) onComplete,
  }) async {
    final process = await Process.start(
      command,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    final stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(onLine);

    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => onLine("[ERR] $line"));

    process.exitCode.then(onComplete);

    return CommandSubscription(stdoutSub, stderrSub);
  }
}
