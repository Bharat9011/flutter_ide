import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:laravelide/GetProvider/new_project_getx_provider.dart';
import 'package:laravelide/db/data_base_handler.dart';
import 'package:laravelide/screens/project_screen.dart';
import 'package:laravelide/widgets/dialog/project_dialog.dart';
import 'package:window_size/window_size.dart';
import '../models/project_model.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<HomeScreen> {
  String? folderPath;

  List<ProjectModel> projectList = [];

  @override
  void initState() {
    super.initState();
    _setWindowSize(1200, 800);
    getProjectList();
  }

  void getProjectList() async {
    final projects = await DataBaseHandler.instance.queryAllUsers();
    setState(() {
      projectList = projects;
    });
  }

  void _setWindowSize(double width, double height) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setWindowMinSize(Size(width, height));
      setWindowMaxSize(Size.infinite);
      setWindowFrame(Rect.fromLTWH(100, 100, width, height));
    }
  }

  Future<void> pickFolder() async {
    final path = await getDirectoryPath();
    if (path != null) {
      folderPath = path;
      List<String> projectNameSplit = folderPath.toString().split("\\");
      String projectName = projectNameSplit[projectNameSplit.length - 1];

      var newProjectController = Get.put(NewProjectGetxProvider());

      newProjectController.setName(projectName);
      newProjectController.setPath(folderPath.toString());
      newProjectController.markCreated(true);

      await DataBaseHandler.instance.insertUser(
        ProjectModel(
          name: projectName,
          path: folderPath.toString(),
          isCreated: "false",
        ),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProjectScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceContainerLow,
                  colorScheme.surfaceContainer,
                ],
              ),
              border: Border(
                right: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.code,
                          color: colorScheme.onPrimaryContainer,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Laravel IDE',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v1.0.0 • 2025',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),

                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.folder_open_rounded,
                        label: 'Projects',
                        isActive: true,
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context,
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        isActive: false,
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context,
                        icon: Icons.palette_rounded,
                        label: 'Themes',
                        isActive: false,
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context,
                        icon: Icons.extension_rounded,
                        label: 'Extensions',
                        isActive: false,
                      ),
                    ],
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person_rounded,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Developer',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Active',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainerLowest,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Top Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.8),
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: pickFolder,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Open Project'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => const ProjectDialog(),
                            );
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('New Project'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          padding: const EdgeInsets.all(32),
                          child: projectList.isEmpty
                              ? _buildEmptyState(colorScheme)
                              : _buildProjectList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Illustration
        Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.tertiaryContainer.withOpacity(0.3),
              ],
            ),
          ),
          child: Icon(
            Icons.rocket_launch_rounded,
            size: 120,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(height: 48),

        // Title
        Text(
          'Start Your Laravel Project',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Description
        Text(
          'Open an existing Laravel project or create a new one to get started with development',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 48),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: pickFolder,
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Open Project'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Create project feature coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Project'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Quick Actions
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAction(
                    context,
                    icon: Icons.history_rounded,
                    label: 'Recent',
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.star_rounded,
                    label: 'Favorites',
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.info_outline_rounded,
                    label: 'Docs',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectList() {
    return Column(
      children: projectList
          .map(
            (project) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.folder),
                title: Text(project.name),
                subtitle: Text(project.path),
                trailing: PopupMenuButton<int>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 1) {
                      // Handle Edit
                    } else if (value == 2) {
                      // Handle Delete
                    }
                  },
                  itemBuilder: (context) => [
                    // const PopupMenuItem(
                    //   value: 1,
                    //   child: Row(
                    //     children: [
                    //       Icon(Icons.edit_outlined, color: Colors.blue),
                    //       SizedBox(width: 10),
                    //       Text("Edit"),
                    //     ],
                    //   ),
                    // ),
                    const PopupMenuItem(
                      value: 1,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Text("Delete"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 2,
                      child: Row(
                        children: [
                          Icon(Icons.folder_outlined, color: Colors.blue),
                          SizedBox(width: 10),
                          Text("Show in explorer"),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  var newProjectProvider = Get.put(NewProjectGetxProvider());

                  newProjectProvider.setName(project.name);
                  newProjectProvider.setPath(project.path);
                  newProjectProvider.setPlatform(project.platform.toString());
                  newProjectProvider.setProjectType(
                    project.projectType.toString(),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProjectScreen()),
                  );
                },
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {},
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label feature coming soon!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
