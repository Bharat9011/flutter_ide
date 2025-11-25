import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

  // Flutter vs Dart
  String _selectedPlatform = 'Flutter';

  // Default types
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

  Future<void> _selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    setState(() {
      _selectedFolderPath = selectedDirectory;
    });
  }

  List<String> get _currentTypes =>
      _selectedPlatform == 'Flutter' ? _flutterTypes : _dartTypes;

  @override
  void initState() {
    super.initState();
    _selectedProjectType = _currentTypes.first;
  }

  @override
  Widget build(BuildContext context) {
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

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _projectNameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedFolderPath ?? 'No folder selected',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _selectedFolderPath == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _selectFolder,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Select Folder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final projectName = _projectNameController.text.trim();
            if (projectName.isEmpty ||
                _selectedFolderPath == null ||
                _selectedProjectType == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectScreen(
                  projectModel: ProjectModel(
                    name: projectName,
                    path: _selectedFolderPath.toString(),
                    isCreated: "true",
                    platform: _selectedPlatform,
                    projectType: _selectedProjectType!,
                  ),
                ),
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
