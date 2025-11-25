import 'dart:io';
import 'package:path/path.dart' as p;

class ProjectService {
  static Future<String?> createLaravelProject(String projectName) async {
    try {
      final currentDir = Directory.current.path;
      final projectPath = p.join(currentDir, projectName);

      ProcessResult result = await Process.run(
        'composer',
        ['create-project', 'laravel/laravel', projectName],
        workingDirectory: currentDir,
        runInShell: true,
      );

      if (result.exitCode == 0) {
        print('Project created successfully');
        return projectPath;
      } else {
        print('Error: ${result.stderr}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }
}
