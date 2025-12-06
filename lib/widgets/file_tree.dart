import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:laravelide/GetProvider/new_project_getx_provider.dart';
import 'package:path/path.dart' as path;

class FileTree extends StatefulWidget {
  // final String? projectPath;
  final void Function(String)? onFileSelected;
  // final List<String> excludedDirs;

  const FileTree({
    super.key,
    // this.projectPath,
    this.onFileSelected,
    // this.excludedDirs = const [],
  });

  @override
  State<FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends State<FileTree> {
  List<FileSystemEntity>? _rootContents;
  String? _error;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  // File system watcher for auto-refresh
  StreamSubscription<FileSystemEvent>? _watcher;
  Timer? _debounceTimer;

  static String? clipboardPath;

  @override
  void initState() {
    super.initState();

    final controller = Get.find<NewProjectGetxProvider>();

    ever(controller.path, (_) {
      _loadRootContents();
      _setupFileWatcher();
    });

    _loadRootContents();
    _setupFileWatcher();
  }

  @override
  void dispose() {
    _watcher?.cancel();
    _debounceTimer?.cancel();
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _setupFileWatcher() async {
    await _watcher?.cancel();

    final controller = Get.find<NewProjectGetxProvider>();
    final projectPath = controller.path.value;

    if (projectPath.isEmpty) return;

    final dir = Directory(projectPath);
    if (!dir.existsSync()) {
      debugPrint('Directory does not exist for watcher: $projectPath');
      return;
    }

    try {
      _watcher = dir.watch(recursive: true).listen((event) {
        // Debounce multiple rapid events
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            debugPrint('File system change detected: ${event.path}');
            _loadRootContents();
          }
        });
      });
    } catch (e) {
      debugPrint('Failed to setup file watcher: $e');
    }
  }

  Future<void> _loadRootContents() async {
    final controller = Get.find<NewProjectGetxProvider>();
    final projectPath = controller.path.value;

    if (projectPath.isEmpty) {
      setState(() {
        _rootContents = null;
        _error = "No project path set";
      });
      return;
    }

    final dir = Directory(projectPath);

    if (!dir.existsSync()) {
      setState(() {
        _error = "Project directory does NOT exist:\n$projectPath";
      });
      return;
    }

    setState(() {
      _error = null;
    });

    try {
      final checkFlutterProject = Directory(controller.path.value);

      await Future.delayed(Duration(seconds: 3));
      final contents = await _getDirectoryContents(checkFlutterProject);

      if (mounted) {
        setState(() {
          _rootContents = contents;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<List<FileSystemEntity>> _getDirectoryContents(Directory dir) async {
    try {
      final entities = await dir.list().where((entity) {
        return true;
      }).toList();

      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return path
            .basename(a.path)
            .toLowerCase()
            .compareTo(path.basename(b.path).toLowerCase());
      });

      return entities;
    } catch (e) {
      debugPrint('Error reading directory: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NewProjectGetxProvider>();
    final projectPath = controller.path.value;

    if (projectPath.isEmpty) {
      return const Center(child: Text("No project opened"));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading directory:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_rootContents == null || _rootContents!.isEmpty) {
      return const Center(
        child: Text(
          'Folder is empty, please wait...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 600,
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _verticalController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _rootContents!.length,
              itemBuilder: (context, index) {
                final entity = _rootContents![index];
                final isDir = entity is Directory;

                if (isDir) {
                  return _DirectoryTile(
                    key: ValueKey(entity.path),
                    directory: entity,
                    onFileSelected: widget.onFileSelected,
                  );
                } else {
                  return _FileTile(
                    key: ValueKey(entity.path),
                    file: entity as File,
                    onTap: () => widget.onFileSelected?.call(entity.path),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectoryTile extends StatefulWidget {
  final Directory directory;
  final int level;
  final void Function(String)? onFileSelected;

  const _DirectoryTile({
    super.key,
    required this.directory,
    this.level = 0,
    this.onFileSelected,
  });

  @override
  State<_DirectoryTile> createState() => _DirectoryTileState();
}

class _DirectoryTileState extends State<_DirectoryTile> {
  bool _isExpanded = false;
  List<FileSystemEntity>? _children;
  String? _error;
  String? _creatingType;
  final TextEditingController _createController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  // File watcher for this directory
  StreamSubscription<FileSystemEvent>? _dirWatcher;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _dirWatcher?.cancel();
    _debounceTimer?.cancel();
    _createController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setupDirectoryWatcher() async {
    await _dirWatcher?.cancel();

    if (!_isExpanded) return;

    try {
      _dirWatcher = widget.directory.watch(recursive: false).listen((event) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted && _isExpanded) {
            debugPrint('Directory change detected: ${event.path}');
            _refresh();
          }
        });
      });
    } catch (e) {
      debugPrint('Failed to watch directory: $e');
    }
  }

  Future<void> _toggleExpansion() async {
    if (!_isExpanded && _children == null) {
      try {
        final children = await _getDirectoryContents(widget.directory);
        if (mounted) {
          setState(() {
            _children = children;
            _isExpanded = true;
            _error = null;
          });
          _setupDirectoryWatcher();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
          });
        }
      }
    } else {
      setState(() => _isExpanded = !_isExpanded);
      if (_isExpanded) {
        _refresh(); // Refresh when expanding
        _setupDirectoryWatcher();
      } else {
        await _dirWatcher?.cancel();
      }
    }
  }

  Future<List<FileSystemEntity>> _getDirectoryContents(Directory dir) async {
    try {
      final entities = await dir.list().where((entity) {
        final name = path.basename(entity.path);
        // if (entity is Directory && widget.excludedDirs.contains(name)) {
        //   return false;
        // }
        return true;
      }).toList();

      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return path
            .basename(a.path)
            .toLowerCase()
            .compareTo(path.basename(b.path).toLowerCase());
      });

      return entities;
    } catch (e) {
      debugPrint('Error reading directory: $e');
      rethrow;
    }
  }

  void _showFolderContextMenu(BuildContext context, Offset position) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: const [
        PopupMenuItem(value: 'new_file', child: Text('New File')),
        PopupMenuItem(value: 'new_folder', child: Text('New Folder')),
        PopupMenuItem(value: 'copy', child: Text('Copy')),
        PopupMenuItem(value: 'paste', child: Text('Paste')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );

    if (selected == null) return;

    final dir = widget.directory;

    switch (selected) {
      case 'new_file':
        _showInlineInput('file');
        break;
      case 'new_folder':
        _showInlineInput('folder');
        break;
      case 'copy':
        _FileTreeState.clipboardPath = dir.path;
        debugPrint('Copied folder: ${dir.path}');
        break;
      case 'paste':
        if (_FileTreeState.clipboardPath != null) {
          final source = _FileTreeState.clipboardPath!;
          final target = path.join(dir.path, path.basename(source));
          final type = FileSystemEntity.typeSync(source);
          try {
            if (type == FileSystemEntityType.directory) {
              await _copyDirectory(Directory(source), Directory(target));
            } else if (type == FileSystemEntityType.file) {
              await File(target).writeAsBytes(await File(source).readAsBytes());
            }
            _refresh();
          } catch (e) {
            debugPrint('Paste failed: $e');
          }
        }
        break;
      case 'delete':
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          debugPrint('Deleted folder: ${dir.path}');
        }
        _refresh();
        break;
    }
  }

  Future<void> _copyDirectory(Directory source, Directory dest) async {
    if (!await dest.exists()) {
      await dest.create(recursive: true);
    }

    await for (final entity in source.list(recursive: false)) {
      final newPath = path.join(dest.path, path.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await File(newPath).writeAsBytes(await entity.readAsBytes());
      }
    }
  }

  void _showInlineInput(String type) {
    setState(() {
      _creatingType = type;
      _isExpanded = true;
      _children ??= [];
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      _focusNode.requestFocus();
    });
  }

  Future<void> _createEntity() async {
    final name = _createController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _creatingType = null;
        _createController.clear();
      });
      return;
    }

    final newPath = path.join(widget.directory.path, name);
    try {
      if (_creatingType == 'folder') {
        await Directory(newPath).create(recursive: true);
      } else {
        await File(newPath).create(recursive: true);
      }
      _createController.clear();
      setState(() {
        _creatingType = null;
      });
      _refresh();
    } catch (e) {
      debugPrint('Creation failed: $e');
    }
  }

  void _refresh() async {
    try {
      final updated = await _getDirectoryContents(widget.directory);
      if (mounted) {
        setState(() => _children = updated);
      }
    } catch (e) {
      debugPrint('Refresh failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = path.basename(widget.directory.path);
    final indent = widget.level * 16.0;
    final hoverColor = Theme.of(context).hoverColor.withOpacity(0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Listener(
          onPointerDown: (event) {
            if (event.kind == PointerDeviceKind.mouse &&
                event.buttons == kSecondaryMouseButton) {
              _showFolderContextMenu(context, event.position);
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Container(
              color: _isHovered ? hoverColor : Colors.transparent,
              child: InkWell(
                onTap: _toggleExpansion,
                borderRadius: BorderRadius.circular(4),
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: indent,
                    right: 8,
                    top: 4,
                    bottom: 4,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.folder_open : Icons.folder,
                        size: 20,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        if (_error != null)
          Padding(
            padding: EdgeInsets.only(left: indent + 48),
            child: Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        if (_isExpanded && _children != null) ...[
          for (final entity in _children!)
            if (entity is Directory)
              _DirectoryTile(
                key: ValueKey(entity.path),
                directory: entity,
                level: widget.level + 1,
                onFileSelected: widget.onFileSelected,
              )
            else
              _FileTile(
                key: ValueKey(entity.path),
                file: entity as File,
                level: widget.level + 1,
                onTap: () => widget.onFileSelected?.call(entity.path),
              ),

          if (_creatingType != null)
            Padding(
              padding: EdgeInsets.only(left: indent + 40, top: 4),
              child: Row(
                children: [
                  Icon(
                    _creatingType == 'folder'
                        ? Icons.folder
                        : Icons.insert_drive_file,
                    color: _creatingType == 'folder'
                        ? Colors.amber[700]
                        : Colors.grey[600],
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _createController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Enter name...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _createEntity(),
                      onEditingComplete: _createEntity,
                      onTapOutside: (_) {
                        setState(() => _creatingType = null);
                        _createController.clear();
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _FileTile extends StatefulWidget {
  final File file;
  final int level;
  final VoidCallback? onTap;

  const _FileTile({super.key, required this.file, this.level = 0, this.onTap});

  @override
  State<_FileTile> createState() => _FileTileState();
}

class _FileTileState extends State<_FileTile> {
  bool _isHovered = false;

  IconData _getFileIcon(String extension, String fileName) {
    if (fileName == 'pubspec.yaml') return Icons.inventory_2;
    if (fileName == 'pubspec.lock') return Icons.lock;
    if (fileName == 'analysis_options.yaml') return Icons.analytics;
    if (fileName == '.gitignore') return Icons.remove_circle_outline;
    if (fileName == 'README.md') return Icons.article;
    if (fileName == '.env') return Icons.settings_applications;

    switch (extension.toLowerCase()) {
      case '.dart':
        return Icons.flutter_dash;
      case '.json':
        return Icons.data_object;
      case '.yaml':
      case '.yml':
        return Icons.settings;
      case '.md':
        return Icons.description;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.webp':
        return Icons.image;
      case '.gif':
        return Icons.gif;
      case '.svg':
        return Icons.vignette;
      case '.txt':
        return Icons.text_snippet;
      case '.xml':
        return Icons.code;
      case '.gradle':
        return Icons.android;
      case '.swift':
      case '.m':
      case '.h':
        return Icons.apple;
      case '.kt':
      case '.java':
        return Icons.code;
      case '.html':
        return Icons.html;
      case '.css':
        return Icons.css;
      case '.js':
        return Icons.javascript;
      case '.ts':
        return Icons.code;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.folder_zip;
      case '.apk':
        return Icons.android;
      case '.ipa':
        return Icons.phone_iphone;
      case '.ttf':
      case '.otf':
        return Icons.font_download;
      case '.mp3':
      case '.wav':
        return Icons.audio_file;
      case '.mp4':
      case '.mov':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String extension, String fileName) {
    // Special files
    if (fileName == 'pubspec.yaml') return Colors.blue[700]!;
    if (fileName == 'pubspec.lock') return Colors.grey[700]!;
    if (fileName == 'analysis_options.yaml') return Colors.purple;
    if (fileName == '.gitignore') return Colors.red[700]!;
    if (fileName == 'README.md') return Colors.green[700]!;
    if (fileName == '.env') return Colors.orange[700]!;

    switch (extension.toLowerCase()) {
      case '.dart':
        return const Color(0xFF00B4AB); // Dart/Flutter teal
      case '.json':
        return Colors.yellow[700]!;
      case '.yaml':
      case '.yml':
        return Colors.orange[700]!;
      case '.md':
        return Colors.blue[700]!;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.webp':
        return Colors.purple[400]!;
      case '.gif':
        return Colors.pink;
      case '.svg':
        return Colors.orange;
      case '.gradle':
        return Colors.green[700]!;
      case '.swift':
      case '.m':
      case '.h':
        return Colors.orange[700]!;
      case '.kt':
      case '.java':
        return Colors.blue[700]!;
      case '.html':
        return Colors.orange[700]!;
      case '.css':
        return Colors.blue;
      case '.js':
        return Colors.yellow[700]!;
      case '.xml':
        return Colors.green;
      case '.apk':
        return Colors.green[700]!;
      case '.ipa':
        return Colors.grey[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  void _showContextMenu(BuildContext context, Offset position) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: const [
        PopupMenuItem(value: 'open', child: Text('Open')),
        PopupMenuItem(value: 'copy', child: Text('Copy')),
        PopupMenuItem(value: 'paste', child: Text('Paste')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );

    if (selected == null) return;

    switch (selected) {
      case 'open':
        widget.onTap?.call();
        break;
      case 'copy':
        _FileTreeState.clipboardPath = widget.file.path;
        debugPrint('Copied: ${widget.file.path}');
        break;
      case 'paste':
        if (_FileTreeState.clipboardPath != null) {
          try {
            final source = File(_FileTreeState.clipboardPath!);
            final target = File(
              path.join(
                widget.file.parent.path,
                path.basename(_FileTreeState.clipboardPath!),
              ),
            );
            await target.writeAsBytes(await source.readAsBytes());
          } catch (e) {
            debugPrint('Paste failed: $e');
          }
        }
        break;
      case 'delete':
        try {
          await widget.file.delete(recursive: true);
          debugPrint('Deleted: ${widget.file.path}');
          if (mounted) setState(() {});
        } catch (e) {
          debugPrint('Delete failed: $e');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = path.basename(widget.file.path);
    final extension = path.extension(widget.file.path);
    final indent = widget.level * 16.0;
    final hoverColor = Theme.of(context).hoverColor.withOpacity(0.2);

    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton) {
          _showContextMenu(context, event.position);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          color: _isHovered ? hoverColor : Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(4),
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.only(
                left: indent + 24,
                right: 8,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(extension, name),
                    size: 18,
                    color: _getFileIconColor(extension, name),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
