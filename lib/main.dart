import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laravelide/GetProvider/is_completed_getx_provider.dart';
import 'package:laravelide/GetProvider/new_project_getx_provider.dart';
import 'package:laravelide/db/data_base_handler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DataBaseHandler.instance.initDb();
  Get.put(NewProjectGetxProvider());
  Get.put(IsCompletedGetxProvider());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laravel IDE',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
