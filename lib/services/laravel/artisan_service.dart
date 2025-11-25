import 'package:laravelide/utils/os_utils.dart';

class ArtisanService {
  static Future<void> runStream({
    required String projectPath,
    required List<String> args,
    required Function(String) onLog,
    required Function() onComplete,
  }) async {
    await OSUtils.streamCommand(
      command: 'php',
      args: ['artisan', ...args],
      workingDirectory: projectPath,
      onLine: onLog,
      onComplete: (_) => onComplete(),
    );
  }

  static Future<String> runCommand(
    String projectPath,
    List<String> args,
  ) async {
    final result = await OSUtils.runCommand('php', [
      'artisan',
      ...args,
    ], workingDirectory: projectPath);
    return result.stdout + result.stderr;
  }
}
