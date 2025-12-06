import 'package:get/get.dart';

class NewProjectGetxProvider extends GetxController {
  var name = "".obs;
  var path = "".obs;
  var isCreated = false.obs;
  var platform = "".obs;
  var projectType = "".obs;

  void setName(String value) => name.value = value;

  void setPath(String value) => path.value = value;

  void setPlatform(String value) => platform.value = value;

  void setProjectType(String value) => projectType.value = value;

  void markCreated(bool value) => isCreated.value = value;

  String get fullProjectPath => "${path.value}\\${name.value}";

  void reset() {
    name.value = "";
    path.value = "";
    isCreated.value = false;
    platform.value = "";
    projectType.value = "";
  }
}
