import 'package:laravelide/utils/os_utils.dart';

class PHPService {
  static Future<bool> checkPHPInstalled() async {
    final result = await OSUtils.runCommand('php', ['-v']);
    return result.exitCode == 0;
  }

  static Future<bool> checkLaravelInstalled() async {
    final result = await OSUtils.runCommand('php', ['artisan', '--version']);
    return result.exitCode == 0;
  }
}
