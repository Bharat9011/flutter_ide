import 'package:flutter/material.dart';

class LineNumberPainter extends CustomPainter {
  final int lineCount;
  final double scrollOffset;
  final double lineHeight;
  final BuildContext context;
  final double horizontalPadding;
  final int currentLine;

  LineNumberPainter({
    required this.lineCount,
    required this.scrollOffset,
    required this.lineHeight,
    required this.context,
    this.horizontalPadding = 8.0,
    this.currentLine = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lineCount <= 0 || size.height <= 0 || size.width <= 0) return;

    final int firstVisibleLine = (scrollOffset / lineHeight).floor().clamp(
      0,
      lineCount,
    );
    final int lastVisibleLine = ((scrollOffset + size.height) / lineHeight)
        .ceil()
        .clamp(0, lineCount);

    final TextDirection textDirection = Directionality.of(context);

    for (int i = firstVisibleLine; i < lastVisibleLine; i++) {
      final String text = (i + 1).toString();
      final bool isCurrentLine = (i + 1) == currentLine;

      final TextSpan span = TextSpan(
        text: text,
        style: TextStyle(
          color: isCurrentLine ? Colors.white : const Color(0xFF858585),
          fontSize: 14.0,
          fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
        ),
      );

      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.right,
        textDirection: textDirection,
      );

      tp.layout(minWidth: 0, maxWidth: size.width - horizontalPadding * 2);

      final double y =
          (i * lineHeight) - scrollOffset + (lineHeight - tp.height) / 2;
      final double x = size.width - tp.width - horizontalPadding;

      if (y + tp.height > 0 && y < size.height) {
        // Draw current line background
        if (isCurrentLine) {
          final paint = Paint()
            ..color = const Color(0xFF2A2A2A)
            ..style = PaintingStyle.fill;
          canvas.drawRect(
            Rect.fromLTWH(0, y - 2, size.width, lineHeight),
            paint,
          );
        }
        tp.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineNumberPainter old) {
    return old.lineCount != lineCount ||
        old.scrollOffset != scrollOffset ||
        old.lineHeight != lineHeight ||
        old.currentLine != currentLine ||
        old.horizontalPadding != horizontalPadding;
  }
}
