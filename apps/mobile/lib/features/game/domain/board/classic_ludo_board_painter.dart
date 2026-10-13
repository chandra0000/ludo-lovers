import 'package:flutter/material.dart';

import 'board_coordinate_layout.dart';

/// Logical 15x15 board presentation. This is visual geometry only; it does not
/// decide legal moves or map game-engine progress to cells.
class ClassicLudoBoardPainter extends CustomPainter {
  const ClassicLudoBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / 15;
    final left = (size.width - cell * 15) / 2;
    final top = (size.height - cell * 15) / 2;
    final boardRect = Rect.fromLTWH(left, top, cell * 15, cell * 15);

    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, Radius.circular(cell * 0.45)),
      Paint()..color = LudoBoardPalette.black,
    );

    _drawHome(canvas, left, top, cell, 0, 0, LudoBoardPalette.orange);
    _drawHome(canvas, left, top, cell, 9, 0, LudoBoardPalette.green);
    _drawHome(canvas, left, top, cell, 0, 9, LudoBoardPalette.blue);
    _drawHome(canvas, left, top, cell, 9, 9, LudoBoardPalette.magenta);

    final trackPaint = Paint()..color = LudoBoardPalette.cream;
    final linePaint = Paint()
      ..color = const Color(0xFF303438)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    for (var row = 0; row < 15; row++) {
      for (var col = 0; col < 15; col++) {
        final inCentralCross = (row >= 6 && row <= 8) ||
            (col >= 6 && col <= 8);
        if (!inCentralCross) continue;
        final rect = Rect.fromLTWH(
          left + col * cell,
          top + row * cell,
          cell,
          cell,
        );
        canvas.drawRect(rect, trackPaint);
        canvas.drawRect(rect, linePaint);
      }
    }

    _drawLane(canvas, left, top, cell, const Offset(7, 1), const Offset(7, 5),
        LudoBoardPalette.orange);
    _drawLane(canvas, left, top, cell, const Offset(13, 7), const Offset(9, 7),
        LudoBoardPalette.green);
    _drawLane(canvas, left, top, cell, const Offset(7, 13), const Offset(7, 9),
        LudoBoardPalette.blue);
    _drawLane(canvas, left, top, cell, const Offset(1, 7), const Offset(5, 7),
        LudoBoardPalette.magenta);

    final center = Offset(left + 7.5 * cell, top + 7.5 * cell);
    final centerPath = Path()
      ..moveTo(center.dx, center.dy - cell * 1.5)
      ..lineTo(center.dx + cell * 1.5, center.dy)
      ..lineTo(center.dx, center.dy + cell * 1.5)
      ..lineTo(center.dx - cell * 1.5, center.dy)
      ..close();
    canvas.drawPath(centerPath, Paint()..color = LudoBoardPalette.gold);
    canvas.drawPath(centerPath, linePaint);

    _drawStart(canvas, left, top, cell, 6, 1, LudoBoardPalette.orange);
    _drawStart(canvas, left, top, cell, 13, 6, LudoBoardPalette.green);
    _drawStart(canvas, left, top, cell, 8, 13, LudoBoardPalette.blue);
    _drawStart(canvas, left, top, cell, 1, 8, LudoBoardPalette.magenta);
  }

  void _drawHome(Canvas canvas, double left, double top, double cell,
      int col, int row, Color color) {
    final rect = Rect.fromLTWH(
      left + col * cell, top + row * cell, cell * 6, cell * 6,
    );
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.24));
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.12,
    );
    final inner = rect.deflate(cell * 1.05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(cell * 0.6)),
      Paint()..color = color.withValues(alpha: 0.22),
    );
    final tokenPaint = Paint()..color = color;
    for (final point in <Offset>[
      Offset(inner.left + inner.width * 0.3, inner.top + inner.height * 0.3),
      Offset(inner.right - inner.width * 0.3, inner.top + inner.height * 0.3),
      Offset(inner.left + inner.width * 0.3, inner.bottom - inner.height * 0.3),
      Offset(inner.right - inner.width * 0.3, inner.bottom - inner.height * 0.3),
    ]) {
      canvas.drawCircle(point, cell * 0.32, tokenPaint);
      canvas.drawCircle(
        point,
        cell * 0.32,
        Paint()
          ..color = LudoBoardPalette.cream
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.07,
      );
    }
  }

  void _drawLane(Canvas canvas, double left, double top, double cell,
      Offset start, Offset end, Color color) {
    final delta = end - start;
    final steps = delta.dx.abs() + delta.dy.abs();
    final paint = Paint()..color = color.withValues(alpha: 0.8);
    for (var i = 0; i <= steps; i++) {
      final col = start.dx + (steps == 0 ? 0 : delta.dx * i / steps);
      final row = start.dy + (steps == 0 ? 0 : delta.dy * i / steps);
      canvas.drawRect(
        Rect.fromLTWH(left + col * cell, top + row * cell, cell, cell),
        paint,
      );
    }
  }

  void _drawStart(Canvas canvas, double left, double top, double cell,
      int col, int row, Color color) {
    final rect = Rect.fromLTWH(
      left + col * cell, top + row * cell, cell, cell,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(cell * 0.12), Radius.circular(cell * 0.2)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant ClassicLudoBoardPainter oldDelegate) => false;
}
