import 'package:get/get.dart';

class IsCompletedGetxProvider extends GetxController {
  var isCompleted = false.obs;

  void setCompleted(bool value) => isCompleted.value = value;
}
