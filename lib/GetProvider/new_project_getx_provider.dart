import 'dart:developer';

import 'package:get/get.dart';
import 'package:laravelide/GetProvider/debug_log_getx_controller.dart';
import 'package:laravelide/GetProvider/is_completed_getx_provider.dart';
import 'package:laravelide/services/flutter/create_project_utils.dart';

class NewProjectGetxProvider extends GetxController {
  var name = "".obs;
  var path = "".obs;
  var isCreated = false.obs;
  var platform = "".obs;
  var projectType = "".obs;

  @override
  void onInit() {
    super.onInit();
    ever(isCreated, (bool value) {
      if (value) _createProject();
    });
  }

  void _createProject() {
    if (path.value.isEmpty || name.value.isEmpty) {
      return;
    }
    if (platform.value == "Flutter") {
      if (projectType.value == "Flutter App") {
        CreateProjectUtils.createProjectStream(
          parentDir: path.value,
          projectName: name.value,
          onLog: (line) {
            log(line);
            Get.find<DebugLogGetxController>().addLog(line);
            update();
          },
          onComplete: () {
            Get.find<IsCompletedGetxProvider>().setCompleted(true);
            markCreated(false);
          },
        );
      }
    }
  }

  String get fullProjectPath => "$path\\$name";

  void setName(String value) {
    name.value = value;
    update();
  }

  void setPath(String value) {
    path.value = value;
    update();
  }

  void setPlatform(String value) {
    platform.value = value;
    update();
  }

  void setProjectType(String value) {
    projectType.value = value;
    update();
  }

  void markCreated(bool value) {
    isCreated.value = value;
    update();
  }

  void reset() {
    name.value = "";
    // path.value = "";
    isCreated.value = false;
    platform.value = "";
    projectType.value = "";
    update();
  }
}
