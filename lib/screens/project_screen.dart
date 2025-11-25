import 'dart:io';
import 'package:flutter/material.dart';
import 'package:laravelide/models/project_model.dart';
import 'package:laravelide/widgets/menu_strip.dart';
import 'package:window_size/window_size.dart';
import '../widgets/file_tree.dart';
import '../widgets/code_editor.dart';
import '../widgets/terminal_panel.dart';

class ProjectScreen extends StatefulWidget {
  final ProjectModel projectModel;

  const ProjectScreen({super.key, required this.projectModel});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late String _projectPath;
  String? _selectedFilePath;
  final List<String> _openFiles = [];
  int _currentFileIndex = 0;

  // Panel controls
  double _sidebarWidth = 250;
  double _terminalHeight = 200;
  bool _isResizingSidebar = false;
  bool _isResizingTerminal = false;
  bool _isTerminalVisible = true;

  @override
  void initState() {
    super.initState();
    _projectPath = widget.projectModel.path;
    _initializeWindow();
  }

  void _initializeWindow() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setWindowSize(1200, 800);
      });
    }
  }

  void _setWindowSize(double width, double height) {
    try {
      setWindowMinSize(Size(width, height));
      setWindowMaxSize(Size.infinite);

      getCurrentScreen().then((screen) {
        if (screen != null) {
          final screenWidth = screen.frame.width;
          final screenHeight = screen.frame.height;
          final left = (screenWidth - width) / 2;
          final top = (screenHeight - height) / 2;
          setWindowFrame(Rect.fromLTWH(left, top, width, height));
        } else {
          setWindowFrame(Rect.fromLTWH(100, 100, width, height));
        }
      });
    } catch (e) {
      debugPrint('Error setting window size: $e');
    }
  }

  void _handleFileSelection(String filePath) {
    if (filePath == _selectedFilePath) return;

    setState(() {
      _selectedFilePath = filePath;
      if (!_openFiles.contains(filePath)) {
        _openFiles.add(filePath);
        _currentFileIndex = _openFiles.length - 1;
      } else {
        _currentFileIndex = _openFiles.indexOf(filePath);
      }
    });
  }

  void _closeFile(String filePath) {
    setState(() {
      final index = _openFiles.indexOf(filePath);
      _openFiles.remove(filePath);
      if (_selectedFilePath == filePath) {
        if (_openFiles.isEmpty) {
          _selectedFilePath = null;
          _currentFileIndex = 0;
        } else {
          _currentFileIndex = index > 0 ? index - 1 : 0;
          _selectedFilePath = _openFiles[_currentFileIndex];
        }
      }
    });
  }

  void _toggleTerminal() {
    setState(() {
      _isTerminalVisible = !_isTerminalVisible;
    });
  }

  Widget _buildTabBar() {
    if (_openFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _openFiles.length,
        itemBuilder: (context, index) {
          final filePath = _openFiles[index];
          final fileName = filePath.split(Platform.pathSeparator).last;
          final isSelected = filePath == _selectedFilePath;

          return Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.surface
                  : Colors.transparent,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: InkWell(
              onTap: () => _handleFileSelection(filePath),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(
                        fileName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _closeFile(filePath),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResizableHandle({
    required bool isVertical,
    required VoidCallback onDragStart,
    required Function(DragUpdateDetails) onDragUpdate,
    required VoidCallback onDragEnd,
  }) {
    return MouseRegion(
      cursor: isVertical
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        onPanStart: (_) => onDragStart(),
        onPanUpdate: onDragUpdate,
        onPanEnd: (_) => onDragEnd(),
        child: Container(
          width: isVertical ? 4 : null,
          height: isVertical ? null : 4,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: isVertical ? 1 : null,
              height: isVertical ? null : 1,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorArea() {
    return Column(
      children: [
        // File tabs
        _buildTabBar(),

        // Code editor + terminal
        Expanded(
          child: Column(
            children: [
              // Main editor
              Expanded(
                flex: _isTerminalVisible ? 7 : 10,
                child: _selectedFilePath != null
                    ? CodeEditor(filePath: _selectedFilePath)
                    : Center(
                        child: Text(
                          'No file selected',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
              ),

              // Terminal (inside editor area)
              if (_isTerminalVisible) ...[
                _buildResizableHandle(
                  isVertical: false,
                  onDragStart: () => setState(() => _isResizingTerminal = true),
                  onDragUpdate: (details) {
                    setState(() {
                      _terminalHeight = (_terminalHeight - details.delta.dy)
                          .clamp(0.0, 600.0);
                    });
                  },
                  onDragEnd: () => setState(() => _isResizingTerminal = false),
                ),
                SizedBox(
                  height: _terminalHeight,
                  child: SizedBox(
                    height: _terminalHeight,
                    child: TerminalPanel(
                      projectPath: widget.projectModel.path,
                      // workingDirectory: widget.projectModel.path,
                      // onMinimize: _toggleTerminal,
                      // onMaximize: () {
                      //   setState(() {
                      //     _terminalHeight = _terminalHeight < 400 ? 600 : 200;
                      //   });
                      // },
                      // onClose: () {
                      //   setState(() {
                      //     _isTerminalVisible = false;
                      //   });
                      // },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 40, child: MenuStrip()),
          // Sidebar
          Expanded(
            child: Row(
              children: [
                Container(
                  width: _sidebarWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'EXPLORER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: FileTree(
                          projectPath: _projectPath,
                          onFileSelected: _handleFileSelection,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildResizableHandle(
                  isVertical: true,
                  onDragStart: () => setState(() => _isResizingSidebar = true),
                  onDragUpdate: (details) {
                    setState(() {
                      _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(
                        150.0,
                        600.0,
                      );
                    });
                  },
                  onDragEnd: () => setState(() => _isResizingSidebar = false),
                ),

                // Editor + Terminal Area
                Expanded(child: _buildEditorArea()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
