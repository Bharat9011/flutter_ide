import 'package:get/get.dart';
import 'package:laravelide/GetProvider/debug_log_getx_controller.dart';
import 'package:laravelide/GetProvider/new_project_getx_provider.dart';
import 'package:laravelide/services/flutter/terminal_cmd.dart';

class IsRunGetxProvider extends GetxController {
  final debugLogController = Get.find<DebugLogGetxController>();
  final newProjectDetailsController = Get.find<NewProjectGetxProvider>();

  var isRun = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(isRun, (value) {
      if (value == true) {
        _runProject();
      }
    });
  }

  void markCreated(bool value) => isRun.value = value;

  void reset() => isRun.value = false;

  void _runProject() {
    debugLogController.clear();

    final unwantedPatterns = [
      "Flutter run key commands.",
      "r Hot reload.",
      "R Hot restart.",
      "h List all available interactive commands.",
      "d Detach (terminate",
      "c Clear the screen",
      "q Quit (terminate",
    ];

    TerminalCmd.projectRunStream(
      parentDir: newProjectDetailsController.fullProjectPath,
      onLog: (line) {
        if (unwantedPatterns.any((p) => line.trim().startsWith(p))) return;
        debugLogController.addLog(line);
      },
      onComplete: () {
        isRun.value = false;
      },
    );
  }
}
