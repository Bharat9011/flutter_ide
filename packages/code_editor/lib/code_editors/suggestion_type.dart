import 'package:flutter/material.dart';

enum SuggestionType {
  keyword(Icons.key, Color(0xFFC586C0), 'keyword'),
  function(Icons.functions, Color(0xFFDCDCAA), 'function'),
  classType(Icons.class_, Color(0xFF4EC9B0), 'class'),
  method(Icons.functions, Color(0xFFDCDCAA), 'method'),
  variable(Icons.data_object, Color(0xFF9CDCFE), 'variable'),
  type(Icons.code, Color(0xFF4EC9B0), 'type'),
  directive(Icons.alternate_email, Color(0xFFC586C0), 'directive');

  const SuggestionType(this.icon, this.color, this.label);
  final IconData icon;
  final Color color;
  final String label;
}

class SuggestionItem {
  final String text;
  final SuggestionType type;
  final String? description;

  SuggestionItem({required this.text, required this.type, this.description});
}
