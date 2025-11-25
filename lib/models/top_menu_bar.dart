import 'package:flutter/material.dart';

class TopMenuBar extends StatelessWidget {
  final VoidCallback? onNewFile;
  final VoidCallback? onOpenFolder;
  final VoidCallback? onSave;
  final VoidCallback? onToggleTerminal;
  final VoidCallback? onAbout;

  const TopMenuBar({
    super.key,
    this.onNewFile,
    this.onOpenFolder,
    this.onSave,
    this.onToggleTerminal,
    this.onAbout,
  });

  PopupMenuButton<String> _buildMenu(
    String title,
    List<PopupMenuEntry<String>> items,
  ) {
    return PopupMenuButton<String>(
      tooltip: title,
      offset: const Offset(0, 25),
      itemBuilder: (context) => items,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      onSelected: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _buildMenu("File", [
            PopupMenuItem(
              value: "new_file",
              onTap: onNewFile,
              child: const Text("New File"),
            ),
            PopupMenuItem(
              value: "open_folder",
              onTap: onOpenFolder,
              child: const Text("Open Folder"),
            ),
            PopupMenuItem(
              value: "save",
              onTap: onSave,
              child: const Text("Save"),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: "exit",
              child: const Text("Exit"),
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ]),
          _buildMenu("Edit", [
            const PopupMenuItem(value: "undo", child: Text("Undo")),
            const PopupMenuItem(value: "redo", child: Text("Redo")),
            const PopupMenuItem(value: "copy", child: Text("Copy")),
            const PopupMenuItem(value: "paste", child: Text("Paste")),
          ]),
          _buildMenu("View", [
            PopupMenuItem(
              value: "terminal",
              onTap: onToggleTerminal,
              child: const Text("Toggle Terminal"),
            ),
          ]),
          _buildMenu("Help", [
            PopupMenuItem(
              value: "about",
              onTap: onAbout,
              child: const Text("About LaravelIDE"),
            ),
          ]),
          const Spacer(),
          const Text(
            "LaravelIDE",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
