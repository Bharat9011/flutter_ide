import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:path/path.dart' as path;

class FileTree extends StatefulWidget {
  final String? projectPath;
  final void Function(String)? onFileSelected;
  final List<String> excludedDirs;

  const FileTree({
    super.key,
    this.projectPath,
    this.onFileSelected,
    this.excludedDirs = const [],
  });

  @override
  State<FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends State<FileTree> {
  List<FileSystemEntity>? _rootContents;
  bool _isLoading = true;
  String? _error;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  static String? clipboardPath;

  @override
  void initState() {
    super.initState();
    _loadRootContents();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FileTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectPath != widget.projectPath ||
        oldWidget.excludedDirs != widget.excludedDirs) {
      _loadRootContents();
    }
  }

  Future<void> _loadRootContents() async {
    if (widget.projectPath == null) {
      setState(() {
        _rootContents = null;
        _isLoading = false;
      });
      return;
    }

    final dir = Directory(widget.projectPath!);
    if (!dir.existsSync()) {
      setState(() {
        _error = 'Project directory does not exist';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contents = await _getDirectoryContents(dir);
      if (mounted) {
        setState(() {
          _rootContents = contents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<List<FileSystemEntity>> _getDirectoryContents(Directory dir) async {
    try {
      final entities = await dir.list().where((entity) {
        final name = path.basename(entity.path);

        // Only skip explicitly excluded directories.
        if (entity is Directory && widget.excludedDirs.contains(name)) {
          return false;
        }

        // Show everything else, including dotfiles.
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
    if (widget.projectPath == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No project opened',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
        child: Text('Folder is empty', style: TextStyle(color: Colors.grey)),
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
                    excludedDirs: widget.excludedDirs,
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
  final List<String> excludedDirs;

  const _DirectoryTile({
    super.key,
    required this.directory,
    this.level = 0,
    this.onFileSelected,
    required this.excludedDirs,
  });

  @override
  State<_DirectoryTile> createState() => _DirectoryTileState();
}

class _DirectoryTileState extends State<_DirectoryTile> {
  bool _isExpanded = false;
  List<FileSystemEntity>? _children;
  bool _isLoading = false;
  String? _error;
  String? _creatingType; // 'file' or 'folder'
  final TextEditingController _createController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _createController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleExpansion() async {
    if (!_isExpanded && _children == null) {
      setState(() => _isLoading = true);
      try {
        final children = await _getDirectoryContents(widget.directory);
        if (mounted) {
          setState(() {
            _children = children;
            _isExpanded = true;
            _isLoading = false;
            _error = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() => _isExpanded = !_isExpanded);
    }
  }

  Future<List<FileSystemEntity>> _getDirectoryContents(Directory dir) async {
    try {
      final entities = await dir.list().where((entity) {
        final name = path.basename(entity.path);
        if (entity is Directory && widget.excludedDirs.contains(name)) {
          return false;
        }
        // show everything else, including dotfiles
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
        // Let parent rebuild or just refresh this node
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
    final hoverColor = Theme.of(
      context,
    ).hoverColor.withOpacity(0.2); // for rows

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
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
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
                excludedDirs: widget.excludedDirs,
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

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return Icons.code;
      case '.json':
      case '.yaml':
      case '.yml':
        return Icons.settings;
      case '.md':
        return Icons.description;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.svg':
        return Icons.image;
      case '.txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return Colors.blue;
      case '.json':
      case '.yaml':
      case '.yml':
        return Colors.orange;
      case '.md':
        return Colors.grey;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.svg':
        return Colors.purple;
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
            // No direct refresh here; the parent folder will re-read when toggled.
          } catch (e) {
            debugPrint('Paste failed: $e');
          }
        }
        break;
      case 'delete':
        try {
          await widget.file.delete(recursive: true);
          debugPrint('Deleted: ${widget.file.path}');
          // Let parent directory refresh; locally we can just mark as deleted.
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
    final hoverColor = Theme.of(
      context,
    ).hoverColor.withOpacity(0.2); // for rows

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
                    _getFileIcon(extension),
                    size: 18,
                    color: _getFileIconColor(extension),
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
