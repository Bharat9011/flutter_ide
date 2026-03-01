import 'dart:io';

class DirectoryServices {
  static Future<String?> changeDirectory(
    String currentDirectory,
    String newDirectory,
  ) async {
    if (currentDirectory.isEmpty || newDirectory.isEmpty) {
      return null;
    }

    String targetPath;

    if (newDirectory == "..") {
      targetPath = Directory(currentDirectory).parent.path;
    } else if (newDirectory.startsWith("/") || newDirectory.contains(":")) {
      targetPath = newDirectory;
    } else {
      targetPath = "$currentDirectory${Platform.pathSeparator}$newDirectory";
    }

    final folder = Directory(targetPath);

    if (await folder.exists()) {
      return folder.path;
    }

    return null;
  }

  static Future<String?> showFolderList(String cmd) async {
    try {
      if (cmd.isEmpty) return null;

      List<String> folder = [];
    } catch (e) {}
  }
}
