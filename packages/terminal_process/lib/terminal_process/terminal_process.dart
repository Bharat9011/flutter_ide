import 'package:terminal_process/terminal_process/services/directory_services.dart';

class TerminalProcess {
  final String cmd;
  final String currentDirectory;

  TerminalProcess({required this.cmd, required this.currentDirectory});

  Future<dynamic> process() async {
    List<String> parts = cmd.trim().split(RegExp(r"\s+"));

    if (parts.isEmpty) return null;

    switch (parts[0]) {
      case "cd":
        String newDirectory = parts.length > 1 ? parts[1] : "";
        return await DirectoryServices.changeDirectory(
          currentDirectory,
          newDirectory,
        );
    }
  }
}
