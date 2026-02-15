import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:laravelide/GetProvider/new_project_getx_provider.dart';
import 'package:laravelide/db/data_base_handler.dart';
import 'package:laravelide/models/project_model.dart';
import 'package:laravelide/screens/project_screen.dart';

class ProjectDialog extends StatefulWidget {
  const ProjectDialog({super.key});

  @override
  State<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  final TextEditingController _projectNameController = TextEditingController();

  String? _selectedFolderPath;
  String? _folderError; // new
  String? _projectNameError; // new

  String _selectedPlatform = 'Flutter';

  final List<String> _flutterTypes = const [
    'Flutter App',
    'Flutter Module',
    'Flutter Plugin',
    'Flutter Package',
    'Flutter Skeleton',
  ];

  final List<String> _dartTypes = const [
    'Dart Console App',
    'Dart Package',
    'Dart Server (shelf)',
    'Dart Web App',
    'Dart CLI',
  ];

  String? _selectedProjectType;

  Timer? _debounce;

  List<String> get _currentTypes =>
      _selectedPlatform == 'Flutter' ? _flutterTypes : _dartTypes;

  @override
  void initState() {
    super.initState();
    _selectedProjectType = _currentTypes.first;
  }

  // -----------------------------
  // 📌 VALIDATE FLUTTER PROJECT NAME
  // -----------------------------
  bool validateProjectName() {
    final name = _projectNameController.text.trim();

    final regex = RegExp(r'^[a-z][a-z0-9_]*$');

    if (name.isEmpty) {
      _projectNameError = "Project name is required";
      return false;
    }

    if (!regex.hasMatch(name)) {
      _projectNameError =
          "Invalid name. Use lowercase letters, numbers, and _. Must start with a letter.";
      return false;
    }

    _projectNameError = null;
    return true;
  }

  // -----------------------------
  // 📌 CHECK FOLDER + PROJECT NAME EXISTS
  // -----------------------------
  void checkFolderExitOrNot(String? selectedPath) {
    if (selectedPath == null || selectedPath.isEmpty) {
      _folderError = "No folder selected";
      setState(() {});
      return;
    }

    // Validate project name first
    if (!validateProjectName()) {
      setState(() {});
      return;
    }

    final projectName = _projectNameController.text.trim();
    final directory = Directory(selectedPath);

    if (!directory.existsSync()) {
      _folderError = "Folder does not exist";
      setState(() {});
      return;
    }

    // Check if project folder already exists
    final projectFolderPath = "$selectedPath\\$projectName";
    final projectDirectory = Directory(projectFolderPath);

    if (projectDirectory.existsSync()) {
      _folderError = "A folder with this project name already exists";
    } else {
      _folderError = null;
      _selectedFolderPath = selectedPath;
    }

    setState(() {});
  }

  // -----------------------------
  // 📌 SELECT FOLDER
  // -----------------------------
  Future<void> _selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    _selectedFolderPath = selectedDirectory;
    checkFolderExitOrNot(selectedDirectory);
  }

  // -----------------------------
  // 📌 UI START
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final bool isFormValid =
        _selectedFolderPath != null &&
        _folderError == null &&
        _projectNameError == null &&
        _projectNameController.text.isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Create New Project',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // PLATFORM
            Row(
              children: [
                const Text(
                  'Platform:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedPlatform,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'Flutter',
                        child: Text('Flutter'),
                      ),
                      DropdownMenuItem(
                        value: 'Dart',
                        child: Text('Dart (pure Dart project)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedPlatform = value;
                        _selectedProjectType = _currentTypes.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // TYPE
            DropdownButtonFormField<String>(
              value: _selectedProjectType,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Project Type',
              ),
              items: _currentTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProjectType = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // PROJECT NAME
            TextField(
              controller: _projectNameController,
              decoration: InputDecoration(
                labelText: 'Project Name',
                border: const OutlineInputBorder(),
                errorText: _projectNameError,
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  validateProjectName();
                  checkFolderExitOrNot(_selectedFolderPath);
                });
              },
            ),

            const SizedBox(height: 20),

            // FOLDER SELECT
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFolderPath ?? 'No folder selected',
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_folderError != null)
                        Text(
                          _folderError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _selectFolder,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Select Folder'),
                ),
              ],
            ),
          ],
        ),
      ),

      // -----------------------------
      // CREATE BUTTON
      // -----------------------------
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final projectName = _projectNameController.text.trim();

            final controller = Get.find<NewProjectGetxProvider>();

            controller.setName(projectName);
            controller.setPath(_selectedFolderPath!);
            controller.setPlatform(_selectedPlatform);
            controller.setProjectType(_selectedProjectType!);
            controller.markCreated(true); // ✅ LAST

            await DataBaseHandler.instance.insertUser(
              ProjectModel(
                name: projectName,
                path:
                    "${_selectedFolderPath}${Platform.pathSeparator}$projectName",
                isCreated: "false",
              ),
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProjectScreen()),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
