class ProblemTerminalModel {
  final String type;
  final String message;
  final String file;
  final int line;
  final int column;
  final String rule;

  ProblemTerminalModel({
    required this.type,
    required this.message,
    required this.file,
    required this.line,
    required this.column,
    required this.rule,
  });

  
}
