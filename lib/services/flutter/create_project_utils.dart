import 'package:laravelide/services/flutter/os_support/os_utils_flutter.dart';

class CreateProjectUtils {
  static Future<void> createProjectStream({
    required String parentDir,
    required String projectName,
    required Function(String) onLog,
    required Function() onComplete,
  }) async {
    await OsUtilsFlutter.streamCommand(
      command: "flutter",
      args: ["create", projectName],
      workingDirectory: parentDir,
      onLine: onLog,
      onComplete: (_) => onComplete(),
    );
  }
}
