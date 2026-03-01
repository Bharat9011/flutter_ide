import 'dart:io';

import 'package:code_editor/code_editors/line_number_painter.dart';
import 'package:code_editor/code_editors/stylex_highlighter_controller.dart';
import 'package:code_editor/code_editors/suggestion_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CodeEditor extends StatefulWidget {
  const CodeEditor({super.key, this.filePath});

  final String? filePath;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late final StylexHighlighterController _codeController;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final FocusNode _keyboardListenerFocusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<SuggestionItem> _suggestions = [];
  String _currentWord = "";
  int _selectedSuggestionIndex = 0;

  final double _fontSize = 14.0;
  final double _lineHeightMultiplier = 1.4;
  late final double _lineHeight;
  int _lineCount = 1;
  int _currentLineNumber = 1;
  int _currentColumnNumber = 1;

  String _initialCode = "";
  bool _isModified = false;
  bool _showLineNumbers = true;
  bool _wordWrap = false;

  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];
  bool _isUndoRedoOperation = false;

  @override
  void initState() {
    super.initState();
    _lineHeight = _fontSize * _lineHeightMultiplier;
    _codeController = StylexHighlighterController();

    _codeController.addListener(_onTextChanged);
    _scrollController.addListener(() => setState(() {}));
    _textFieldFocusNode.addListener(_onFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialCode.isNotEmpty) {
        _codeController.text = _initialCode.trim();
        // Set cursor to the beginning
        _codeController.selection = const TextSelection.collapsed(offset: 0);
      }
      _updateLineCount();
      _updateCursorPosition();
      _keyboardListenerFocusNode.requestFocus();
      _textFieldFocusNode.requestFocus();
    });

    if (widget.filePath != null) {
      readTextFile(widget.filePath!);
    }
  }

  Future<void> readTextFile(String filePath) async {
    try {
      final file = File(filePath);

      if (await file.exists()) {
        _initialCode = await file.readAsString();
        _codeController.text = _initialCode;

        _codeController.selection = const TextSelection.collapsed(offset: 0);

        _updateLineCount();
        _isModified = false;

        // Scroll to top
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        if (_horizontalScrollController.hasClients) {
          _horizontalScrollController.jumpTo(0);
        }

        setState(() {});
      } else {
        _showMessage('File not found: $filePath');
      }
    } catch (e) {
      _showMessage('Error reading file: $e');
    }
  }

  Future<void> saveFile() async {
    if (widget.filePath == null) return;

    try {
      final file = File(widget.filePath!);
      await file.writeAsString(_codeController.text);
      _isModified = false;
      _showMessage('File saved successfully');
      setState(() {});
    } catch (e) {
      _showMessage('Error saving file: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.removeListener(_onTextChanged);
    _codeController.dispose();
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    _textFieldFocusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    _hideSuggestions();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_textFieldFocusNode.hasFocus) {
      _hideSuggestions();
    }
  }

  void _onTextChanged() {
    if (!_isUndoRedoOperation) {
      _isModified = true;
      _pushToUndoStack();
    }

    _updateLineCount();
    _updateCursorPosition();

    final int cursorPosition = _codeController.selection.baseOffset;
    if (cursorPosition == -1 || !_textFieldFocusNode.hasFocus) {
      _hideSuggestions();
      return;
    }

    final String textUntilCursor = _codeController.text.substring(
      0,
      cursorPosition,
    );

    if (cursorPosition < _codeController.text.length) {
      final charAfterCursor = _codeController.text[cursorPosition];
      if (RegExp(r'[a-zA-Z0-9_]').hasMatch(charAfterCursor)) {
        _hideSuggestions();
        return;
      }
    }

    if (_shouldShowSuggestions(textUntilCursor)) {
      _updateSuggestions(textUntilCursor, cursorPosition);
    } else {
      _hideSuggestions();
    }
  }

  bool _shouldShowSuggestions(String textUntilCursor) {
    return textUntilCursor.endsWith(r'$') ||
        textUntilCursor.endsWith('@') ||
        textUntilCursor.endsWith('->') ||
        textUntilCursor.endsWith('::') ||
        RegExp(r'(\w+)$').hasMatch(textUntilCursor);
  }

  void _updateSuggestions(String textUntilCursor, int cursorPosition) {
    final List<SuggestionItem> suggestions = [];

    bool isAtWordEnd =
        cursorPosition >= _codeController.text.length ||
        !RegExp(r'[a-zA-Z0-9_]').hasMatch(_codeController.text[cursorPosition]);

    if (!isAtWordEnd) {
      _hideSuggestions();
      return;
    }

    if (textUntilCursor.endsWith(r'$')) {
      _currentWord = r'$';
      suggestions.addAll(_getVariableSuggestions());
    } else if (textUntilCursor.endsWith('@')) {
      _currentWord = '@';
      suggestions.addAll(_getBladeSuggestions());
    } else if (textUntilCursor.endsWith('->') ||
        textUntilCursor.endsWith('::')) {
      _currentWord = textUntilCursor.endsWith('->') ? '->' : '::';
      suggestions.addAll(_getMethodSuggestions());
    } else {
      final wordMatch = RegExp(r'(\w+)$').firstMatch(textUntilCursor);
      if (wordMatch != null) {
        _currentWord = wordMatch.group(1)!;
        if (_currentWord.isNotEmpty) {
          suggestions.addAll(_getKeywordSuggestions(_currentWord));
        }
      }
    }

    if (suggestions.isNotEmpty) {
      _suggestions = suggestions;
      _showSuggestions();
    } else {
      _hideSuggestions();
    }
  }

  List<SuggestionItem> _getKeywordSuggestions(String prefix) {
    final suggestions = <SuggestionItem>[];

    for (final keyword in StylexHighlighterController.allKeywords) {
      if (keyword.startsWith(prefix) && keyword != prefix) {
        suggestions.add(
          SuggestionItem(
            text: keyword,
            type: _getKeywordType(keyword),
            description: _getKeywordDescription(keyword),
          ),
        );
      }
    }

    return suggestions..sort((a, b) => a.text.compareTo(b.text));
  }

  List<SuggestionItem> _getVariableSuggestions() {
    return [
      SuggestionItem(
        text: r'$this',
        type: SuggestionType.variable,
        description: 'Current object',
      ),
      SuggestionItem(
        text: r'$request',
        type: SuggestionType.variable,
        description: 'Request object',
      ),
      SuggestionItem(
        text: r'$user',
        type: SuggestionType.variable,
        description: 'User variable',
      ),
      SuggestionItem(
        text: r'$data',
        type: SuggestionType.variable,
        description: 'Data variable',
      ),
      SuggestionItem(
        text: r'$item',
        type: SuggestionType.variable,
        description: 'Item variable',
      ),
      SuggestionItem(
        text: r'$id',
        type: SuggestionType.variable,
        description: 'ID variable',
      ),
    ];
  }

  List<SuggestionItem> _getBladeSuggestions() {
    return StylexHighlighterController.dartConstants.map((directive) {
      return SuggestionItem(
        text: directive,
        type: SuggestionType.directive,
        description: _getBladeDescription(directive),
      );
    }).toList();
  }

  List<SuggestionItem> _getMethodSuggestions() {
    return [
      SuggestionItem(
        text: 'get()',
        type: SuggestionType.method,
        description: 'Retrieve data',
      ),
      SuggestionItem(
        text: 'post()',
        type: SuggestionType.method,
        description: 'Submit data',
      ),
      SuggestionItem(
        text: 'put()',
        type: SuggestionType.method,
        description: 'Update data',
      ),
      SuggestionItem(
        text: 'delete()',
        type: SuggestionType.method,
        description: 'Delete data',
      ),
      SuggestionItem(
        text: 'where()',
        type: SuggestionType.method,
        description: 'Filter query',
      ),
      SuggestionItem(
        text: 'first()',
        type: SuggestionType.method,
        description: 'Get first result',
      ),
      SuggestionItem(
        text: 'all()',
        type: SuggestionType.method,
        description: 'Get all results',
      ),
      SuggestionItem(
        text: 'create()',
        type: SuggestionType.method,
        description: 'Create new record',
      ),
      SuggestionItem(
        text: 'update()',
        type: SuggestionType.method,
        description: 'Update record',
      ),
      SuggestionItem(
        text: 'save()',
        type: SuggestionType.method,
        description: 'Save changes',
      ),
    ];
  }

  SuggestionType _getKeywordType(String keyword) {
    if (keyword.startsWith('@')) {
      return SuggestionType.directive;
    }

    if (StylexHighlighterController.dartControlKeywords.contains(keyword) ||
        StylexHighlighterController.dartModifiers.contains(keyword)) {
      return SuggestionType.keyword;
    }

    if (StylexHighlighterController.dartTypes.contains(keyword)) {
      return SuggestionType.type;
    }

    if (StylexHighlighterController.flutterCoreClasses.contains(keyword)) {
      return SuggestionType.classType;
    }

    if (RegExp(r'^[A-Z]').hasMatch(keyword)) {
      return SuggestionType.classType;
    }

    return SuggestionType.keyword;
  }

  String _getKeywordDescription(String keyword) {
    const descriptions = {
      'if': 'Conditional statement',
      'else': 'Alternative condition',
      'foreach': 'Loop through array',
      'function': 'Function declaration',
      'class': 'Class declaration',
      'public': 'Public access modifier',
      'private': 'Private access modifier',
      'protected': 'Protected access modifier',
      'return': 'Return value',
      'Route': 'Laravel routing facade',
      'DB': 'Database facade',
      'Auth': 'Authentication facade',
      'view': 'Return view',
      'redirect': 'Redirect response',
    };
    return descriptions[keyword] ?? 'PHP/Laravel keyword';
  }

  String _getBladeDescription(String directive) {
    const descriptions = {
      '@if': 'Conditional statement',
      '@foreach': 'Loop through collection',
      '@extends': 'Extend layout',
      '@section': 'Define section',
      '@yield': 'Output section',
      '@include': 'Include partial',
      '@csrf': 'CSRF token field',
      '@method': 'HTTP method spoofing',
    };
    return descriptions[directive] ?? 'Blade directive';
  }

  void _showSuggestions() {
    _selectedSuggestionIndex = 0;
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _hideSuggestions() {
    _currentWord = "";
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _insertSuggestion(SuggestionItem suggestion) {
    final int cursorPosition = _codeController.selection.baseOffset;
    final String text = _codeController.text;
    final int wordStart = cursorPosition - _currentWord.length;
    if (wordStart < 0) return;

    final String textBefore = text.substring(0, wordStart);
    final String textAfter = text.substring(cursorPosition);

    // For special triggers, don't include them in replacement
    String insertText = suggestion.text;
    if (_currentWord == r'$' ||
        _currentWord == '@' ||
        _currentWord == '->' ||
        _currentWord == '::') {
      insertText =
          _currentWord + suggestion.text.replaceFirst(_currentWord, '');
    }

    final String newText = "$textBefore$insertText $textAfter";
    final int newCursorPos = textBefore.length + insertText.length + 1;

    _codeController.text = newText;
    _codeController.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorPos),
    );

    _hideSuggestions();
    _textFieldFocusNode.requestFocus();
  }

  void _pushToUndoStack() {
    if (_undoStack.length >= 50) {
      _undoStack.removeAt(0);
    }
    _undoStack.add(_codeController.value);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.length <= 1) return;

    _isUndoRedoOperation = true;
    _redoStack.add(_codeController.value);
    _undoStack.removeLast();
    _codeController.value = _undoStack.last;
    _isUndoRedoOperation = false;
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    _isUndoRedoOperation = true;
    final value = _redoStack.removeLast();
    _undoStack.add(value);
    _codeController.value = value;
    _isUndoRedoOperation = false;
  }

  void _updateLineCount() {
    final newLines = '\n'.allMatches(_codeController.text).length + 1;
    if (_lineCount != newLines) {
      setState(() {
        _lineCount = newLines;
      });
    }
  }

  void _updateCursorPosition() {
    final cursorPos = _codeController.selection.baseOffset;
    if (cursorPos == -1) return;

    final textBeforeCursor = _codeController.text.substring(0, cursorPos);
    final lineNumber = '\n'.allMatches(textBeforeCursor).length + 1;
    final lastNewLine = textBeforeCursor.lastIndexOf('\n');
    final columnNumber = cursorPos - lastNewLine;

    if (_currentLineNumber != lineNumber ||
        _currentColumnNumber != columnNumber) {
      setState(() {
        _currentLineNumber = lineNumber;
        _currentColumnNumber = columnNumber;
      });
    }
  }

  @override
  void didUpdateWidget(covariant CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      if (widget.filePath != null && widget.filePath!.isNotEmpty) {
        readTextFile(widget.filePath!);
      } else {
        // Reset editor if no file path
        _codeController.text = '';
        _codeController.selection = const TextSelection.collapsed(offset: 0);
        _initialCode = '';
        _isModified = false;
        setState(() {});
      }
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 320,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 24),
            child: Material(
              elevation: 8.0,
              color: const Color(0xFF252526),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF454545), width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      final isSelected = index == _selectedSuggestionIndex;
                      return InkWell(
                        onTap: () => _insertSuggestion(suggestion),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: isSelected
                              ? const Color(0xFF094771)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Icon(
                                suggestion.type.icon,
                                size: 16,
                                color: suggestion.type.color,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suggestion.text,
                                      style: const TextStyle(
                                        color: Color(0xFFD4D4D4),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (suggestion.description != null)
                                      Text(
                                        suggestion.description!,
                                        style: const TextStyle(
                                          color: Color(0xFF858585),
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                suggestion.type.label,
                                style: const TextStyle(
                                  color: Color(0xFF858585),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  KeyEventResult _handleKeyPress(KeyEvent event) {
    // Only handle key down events
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Handle autocomplete navigation - MUST handle BEFORE text field gets the event
    if (_overlayEntry != null && _suggestions.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedSuggestionIndex =
              (_selectedSuggestionIndex + 1) % _suggestions.length;
        });
        _overlayEntry?.markNeedsBuild();
        return KeyEventResult.handled; // Prevent cursor movement
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedSuggestionIndex =
              (_selectedSuggestionIndex - 1 + _suggestions.length) %
              _suggestions.length;
        });
        _overlayEntry?.markNeedsBuild();
        return KeyEventResult.handled; // Prevent cursor movement
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Allow left/right arrows to move cursor and close suggestions
        _hideSuggestions();
        return KeyEventResult.ignored;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _insertSuggestion(_suggestions[_selectedSuggestionIndex]);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.tab) {
        _insertSuggestion(_suggestions[_selectedSuggestionIndex]);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _hideSuggestions();
        return KeyEventResult.handled;
      }
    }

    // Handle Ctrl/Cmd shortcuts
    final isCtrlPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (isCtrlPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        saveFile();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        _undo();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyY ||
          (HardwareKeyboard.instance.isShiftPressed &&
              event.logicalKey == LogicalKeyboardKey.keyZ)) {
        _redo();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Container(
        //   height: 32,
        //   color: const Color(0xFF007ACC),
        //   padding: const EdgeInsets.symmetric(horizontal: 12),
        //   child: Row(
        //     children: [
        //       if (_isModified)
        //         const Icon(Icons.circle, size: 8, color: Colors.white),
        //       if (_isModified) const SizedBox(width: 8),
        //       Expanded(
        //         child: Text(
        //           widget.filePath?.split('/').last ?? 'Untitled',
        //           style: const TextStyle(
        //             color: Colors.white,
        //             fontSize: 13,
        //             fontWeight: FontWeight.w500,
        //           ),
        //         ),
        //       ),
        //       Text(
        //         'Ln $_currentLineNumber, Col $_currentColumnNumber',
        //         style: const TextStyle(color: Colors.white, fontSize: 12),
        //       ),
        //       const SizedBox(width: 16),
        //       Text(
        //         'PHP',
        //         style: const TextStyle(color: Colors.white, fontSize: 12),
        //       ),
        //     ],
        //   ),
        // ),

        // Editor Area
        Expanded(
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                return _handleKeyPress(event);
              }
              return KeyEventResult.ignored;
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line Numbers
                if (_showLineNumbers)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: 60.0,
                        padding: const EdgeInsets.only(top: 10.0),
                        color: const Color(0xFF1E1E1E),
                        child: CustomPaint(
                          size: Size(60, constraints.maxHeight),
                          painter: LineNumberPainter(
                            lineCount: _lineCount,
                            scrollOffset: _scrollController.hasClients
                                ? _scrollController.offset
                                : 0.0,
                            lineHeight: _lineHeight,
                            context: context,
                            currentLine: _currentLineNumber,
                          ),
                        ),
                      );
                    },
                  ),

                if (_showLineNumbers)
                  const VerticalDivider(width: 1, color: Color(0xFF333333)),

                // Code Field
                Expanded(
                  child: CompositedTransformTarget(
                    link: _layerLink,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          notificationPredicate: (notif) => notif.depth == 1,
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final minWidth = constraints.maxWidth.isFinite
                                    ? constraints.maxWidth
                                    : MediaQuery.of(context).size.width - 100;

                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: minWidth,
                                    minHeight: constraints.maxHeight.isFinite
                                        ? constraints.maxHeight
                                        : 0,
                                  ),
                                  child: IntrinsicWidth(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: 10.0,
                                        left: 12.0,
                                        right: 12.0,
                                        bottom: 10.0,
                                      ),
                                      child: EditableText(
                                        controller: _codeController,
                                        focusNode: _textFieldFocusNode,
                                        selectAllOnFocus: true,
                                        selectionColor: Colors.lightBlue,
                                        style: GoogleFonts.courierPrime(
                                          fontSize: 14,
                                          height: 1.4,
                                          letterSpacing: 0.5,
                                        ),
                                        cursorColor: Colors.white,
                                        backgroundCursorColor: Colors.black26,
                                        maxLines: null,
                                        keyboardType: TextInputType.multiline,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        expands: false,
                                        onChanged: (_) {},
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
