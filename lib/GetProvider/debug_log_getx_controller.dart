import 'package:get/get.dart';

class DebugLogGetxController extends GetxController {
  final RxList<String> debugLogs = <String>[].obs;

  void addLog(String log) {
    debugLogs.add(log);
  }

  void clear() {
    debugLogs.clear();
  }
}
