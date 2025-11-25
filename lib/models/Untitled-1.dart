// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:laravelide/models/project_model.dart';
// import 'package:window_size/window_size.dart';

// import '../widgets/file_tree.dart';
// import '../widgets/code_editor.dart';
// import '../widgets/terminal_panel.dart';

// class HomeScreen extends StatefulWidget {
//   final ProjectModel projectModel;

//   const HomeScreen({super.key, required this.projectModel});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   late String _projectPath;
//   String? _selectedFilePath;
//   final List<String> _openFiles = [];
//   int _currentFileIndex = 0;
//   bool _isTerminalVisible = true;

//   @override
//   void initState() {
//     super.initState();
//     _projectPath = widget.projectModel.path;
//     _initializeWindow();
//   }

//   @override
//   void didUpdateWidget(HomeScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.projectModel.path != widget.projectModel.path) {
//       setState(() {
//         _projectPath = widget.projectModel.path;
//         _selectedFilePath = null;
//         _openFiles.clear();
//       });
//     }
//   }

//   void _initializeWindow() {
//     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _setWindowSize(1200, 800);
//       });
//     }
//   }

//   void _setWindowSize(double width, double height) {
//     try {
//       setWindowMinSize(Size(width, height));
//       setWindowMaxSize(Size.infinite);

//       getCurrentScreen().then((screen) {
//         if (screen != null) {
//           final screenWidth = screen.frame.width;
//           final screenHeight = screen.frame.height;
//           final left = (screenWidth - width) / 2;
//           final top = (screenHeight - height) / 2;
//           setWindowFrame(Rect.fromLTWH(left, top, width, height));
//         } else {
//           setWindowFrame(Rect.fromLTWH(100, 100, width, height));
//         }
//       });
//     } catch (e) {
//       debugPrint('Error setting window size: $e');
//     }
//   }

//   void _handleFileSelection(String filePath) {
//     if (filePath == _selectedFilePath) return;

//     setState(() {
//       _selectedFilePath = filePath;
//       if (!_openFiles.contains(filePath)) {
//         _openFiles.add(filePath);
//         _currentFileIndex = _openFiles.length - 1;
//       } else {
//         _currentFileIndex = _openFiles.indexOf(filePath);
//       }
//     });

//     debugPrint('File selected: $filePath');
//   }

//   void _closeFile(String filePath) {
//     setState(() {
//       final index = _openFiles.indexOf(filePath);
//       _openFiles.remove(filePath);

//       if (_selectedFilePath == filePath) {
//         if (_openFiles.isEmpty) {
//           _selectedFilePath = null;
//           _currentFileIndex = 0;
//         } else {
//           _currentFileIndex = index > 0 ? index - 1 : 0;
//           _selectedFilePath = _openFiles[_currentFileIndex];
//         }
//       } else if (_currentFileIndex >= _openFiles.length) {
//         _currentFileIndex = _openFiles.length - 1;
//       }
//     });
//   }

//   Widget _buildTabBar() {
//     if (_openFiles.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       height: 40,
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surfaceContainerHighest,
//         border: Border(
//           bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
//         ),
//       ),
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: _openFiles.length,
//         itemBuilder: (context, index) {
//           final filePath = _openFiles[index];
//           final fileName = filePath.split(Platform.pathSeparator).last;
//           final isSelected = filePath == _selectedFilePath;

//           return Container(
//             decoration: BoxDecoration(
//               color: isSelected
//                   ? Theme.of(context).colorScheme.surface
//                   : Colors.transparent,
//               border: Border(
//                 right: BorderSide(
//                   color: Theme.of(context).dividerColor,
//                   width: 1,
//                 ),
//               ),
//             ),
//             child: InkWell(
//               onTap: () => _handleFileSelection(filePath),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 8,
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       Icons.insert_drive_file,
//                       size: 16,
//                       color: isSelected
//                           ? Theme.of(context).colorScheme.primary
//                           : Theme.of(context).colorScheme.onSurfaceVariant,
//                     ),
//                     const SizedBox(width: 8),
//                     ConstrainedBox(
//                       constraints: const BoxConstraints(maxWidth: 150),
//                       child: Text(
//                         fileName,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: isSelected
//                               ? FontWeight.w500
//                               : FontWeight.normal,
//                           color: isSelected
//                               ? Theme.of(context).colorScheme.onSurface
//                               : Theme.of(context).colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     InkWell(
//                       onTap: () => _closeFile(filePath),
//                       child: Icon(
//                         Icons.close,
//                         size: 16,
//                         color: Theme.of(context).colorScheme.onSurfaceVariant,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildEditorArea() {
//     return Column(
//       children: [
//         _buildTabBar(),
//         Expanded(
//           child: _selectedFilePath != null
//               ? CodeEditor(filePath: _selectedFilePath)
//               : Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.code,
//                         size: 64,
//                         color: Theme.of(context).colorScheme.outline,
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'No file selected',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Theme.of(context).colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Select a file from the project tree to start editing',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Theme.of(context).colorScheme.outline,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // --- Top Menu Bar (VS Code style)
//           TopMenuBar(
//             onNewFile: () => debugPrint("New File clicked"),
//             onOpenFolder: () => debugPrint("Open Folder clicked"),
//             onSave: () => debugPrint("Save clicked"),
//             onToggleTerminal: () {
//               setState(() => _isTerminalVisible = !_isTerminalVisible);
//             },
//             onAbout: () => showAboutDialog(
//               context: context,
//               applicationName: "LaravelIDE",
//               applicationVersion: "1.0.0",
//               applicationLegalese: "© 2025 Your Name",
//             ),
//           ),

//           // --- Main Editor Area
//           Expanded(
//             child: Row(
//               children: [
//                 // Explorer sidebar
//                 Container(
//                   width: 250,
//                   decoration: BoxDecoration(
//                     color: Theme.of(
//                       context,
//                     ).colorScheme.surfaceContainerHighest,
//                     border: Border(
//                       right: BorderSide(
//                         color: Theme.of(context).dividerColor,
//                         width: 1,
//                       ),
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           border: Border(
//                             bottom: BorderSide(
//                               color: Theme.of(context).dividerColor,
//                               width: 1,
//                             ),
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             const Text(
//                               'EXPLORER',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w600,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                             const Spacer(),
//                             IconButton(
//                               icon: const Icon(Icons.refresh, size: 16),
//                               padding: EdgeInsets.zero,
//                               constraints: const BoxConstraints(),
//                               tooltip: 'Refresh',
//                               onPressed: () => setState(() {}),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Expanded(
//                         child: FileTree(
//                           projectPath: _projectPath,
//                           onFileSelected: _handleFileSelection,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Code editor area
//                 Expanded(child: _buildEditorArea()),
//               ],
//             ),
//           ),
//         ],
//       ),

//       // --- Terminal (toggle visibility)
//       bottomNavigationBar: _isTerminalVisible ? const TerminalPanel() : null,
//     );
//   }
// }
