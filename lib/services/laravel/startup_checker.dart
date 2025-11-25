import 'dart:io';
import 'composer_service.dart';
import 'php_service.dart';

class StartupChecker {
  static Future<List<String>> checkEnvironment() async {
    final logs = <String>[];

    // Check PHP
    final php = await PHPService.checkPHPInstalled();
    logs.add(php ? '✅ PHP found' : '❌ PHP not found');

    // Check Composer
    final composer = await ComposerService.checkComposerInstalled();
    logs.add(composer ? '✅ Composer found' : '❌ Composer not found');

    // Check Laravel installer
    final laravel = await ComposerService.checkLaravelInstalled();
    logs.add(laravel ? '✅ Laravel installer found' : '⚠️ Laravel installer not found (use composer global require laravel/installer)');

    // Check MySQL presence (optional)
    try {
      final mysql = await Process.run('mysql', ['--version']);
      logs.add(mysql.exitCode == 0 ? '✅ MySQL found' : '⚠️ MySQL not found');
    } catch (_) {
      logs.add('⚠️ MySQL not found');
    }

    return logs;
  }
}
