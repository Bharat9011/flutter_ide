import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laravelide/GetProvider/debug_log_getx_controller.dart';
import 'package:laravelide/GetProvider/is_completed_getx_provider.dart';
import 'package:laravelide/GetProvider/is_run_getx_provider.dart';
import 'package:laravelide/GetProvider/new_project_getx_provider.dart';
import 'package:laravelide/db/data_base_handler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DataBaseHandler.instance.initDb();

  Get.put(DebugLogGetxController());
  Get.put(NewProjectGetxProvider());
  Get.put(IsCompletedGetxProvider());
  Get.put(IsRunGetxProvider());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Laravel IDE',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
