import 'package:flutter/material.dart';

import 'classic_ludo_board_definition.dart';
import 'board_coordinate_layout.dart';

/// Visual board prototype driven by the shared seat definition.
///
/// The renderer still uses provisional anchors; logical track IDs are not yet
/// mapped to every displayed cell and this painter does not implement gameplay.
class ClassicLudoBoardPainter extends CustomPainter {
  const ClassicLudoBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    ClassicLudoBoardDefinition.validate();
    const grid = ClassicLudoBoardDefinition.gridSize;
    final cell = size.shortestSide / grid;
    final left = (size.width - cell * grid) / 2;
    final top = (size.height - cell * grid) / 2;
    final boardRect = Rect.fromLTWH(left, top, cell * grid, cell * grid);

    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, Radius.circular(cell * 0.45)),
      Paint()..color = LudoBoardPalette.black,
    );

    for (final seat in ClassicLudoBoardDefinition.seats) {
      _drawHome(canvas, left, top, cell, seat.yardColumn, seat.yardRow, seat.color);
    }

    final trackPaint = Paint()..color = LudoBoardPalette.cream;
    final linePaint = Paint()
      ..color = const Color(0xFF303438)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    for (var row = 0; row < grid; row++) {
      for (var col = 0; col < grid; col++) {
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

    for (final seat in ClassicLudoBoardDefinition.seats) {
      _drawLane(
        canvas, left, top, cell,
        Offset(seat.laneStart.column.toDouble(), seat.laneStart.row.toDouble()),
        Offset(seat.laneEnd.column.toDouble(), seat.laneEnd.row.toDouble()),
        seat.color,
      );
    }

    final center = Offset(left + 7.5 * cell, top + 7.5 * cell);
    final centerPath = Path()
      ..moveTo(center.dx, center.dy - cell * 1.5)
      ..lineTo(center.dx + cell * 1.5, center.dy)
      ..lineTo(center.dx, center.dy + cell * 1.5)
      ..lineTo(center.dx - cell * 1.5, center.dy)
      ..close();
    canvas.drawPath(centerPath, Paint()..color = LudoBoardPalette.gold);
    canvas.drawPath(centerPath, linePaint);

    for (final seat in ClassicLudoBoardDefinition.seats) {
      _drawStart(
        canvas, left, top, cell,
        seat.startMarker.column, seat.startMarker.row, seat.color,
      );
    }
  }

  void _drawHome(
    Canvas canvas, double left, double top, double cell,
    int col, int row, Color color,
  ) {
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

  void _drawLane(
    Canvas canvas, double left, double top, double cell,
    Offset start, Offset end, Color color,
  ) {
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

  void _drawStart(
    Canvas canvas, double left, double top, double cell,
    int col, int row, Color color,
  ) {
    final rect = Rect.fromLTWH(
      left + col * cell, top + row * cell, cell, cell,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(cell * 0.12), Radius.circular(cell * 0.2),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant ClassicLudoBoardPainter oldDelegate) => false;
}
