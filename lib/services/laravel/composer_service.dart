import 'package:laravelide/utils/os_utils.dart';

class ComposerService {
  static Future<String> runInstall(String projectPath) async {
    final result = await OSUtils.runCommand('composer', ['install'], workingDirectory: projectPath);
    return result.stdout + result.stderr;
  }

  static Future<String> runUpdate(String projectPath) async {
    final result = await OSUtils.runCommand('composer', ['update'], workingDirectory: projectPath);
    return result.stdout + result.stderr;
  }

  static Future<String> checkVersion() async {
    final result = await OSUtils.runCommand('composer', ['--version']);
    return result.stdout;
  }

  static Future<void> createProjectStream({
    required String parentDir,
    required String projectName,
    required Function(String) onLog,
    required Function() onComplete,
  }) async {
    await OSUtils.streamCommand(
      command: 'composer',
      args: ['create-project', 'laravel/laravel', projectName],
      workingDirectory: parentDir,
      onLine: onLog,
      onComplete: (_) => onComplete(),
    );
  }

  static Future<void> requirePackage({
    required String projectPath,
    required String package,
    required Function(String) onLog,
    required Function() onComplete,
  }) async {
    await OSUtils.streamCommand(
      command: 'composer',
      args: ['require', package],
      workingDirectory: projectPath,
      onLine: onLog,
      onComplete: (_) => onComplete(),
    );
  }

  static Future<bool> checkComposerInstalled() async {
    final result = await OSUtils.runCommand('composer', ['--version']);
    return result.exitCode == 0;
  }

  static Future<bool> checkLaravelInstalled() async {
    final result = await OSUtils.runCommand('laravel', ['--version']);
    return result.exitCode == 0;
  }
}
