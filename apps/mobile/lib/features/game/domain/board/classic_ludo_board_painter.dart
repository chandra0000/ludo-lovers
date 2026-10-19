import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'board_coordinate_layout.dart';
import 'classic_ludo_board_coordinate_factory.dart';
import 'classic_ludo_board_definition.dart';

/// Visual board prototype driven by the shared seat definition.
///
/// Safe-square stars are drawn from the same provisional cell IDs consumed by
/// the local rules engine. The route is still not approved for release.
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
      _drawHome(
        canvas, left, top, cell, seat.yardColumn, seat.yardRow, seat.color,
      );
    }

    final trackPaint = Paint()..color = LudoBoardPalette.cream;
    final linePaint = Paint()
      ..color = const Color(0xFF303438)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    for (var row = 0; row < grid; row++) {
      for (var col = 0; col < grid; col++) {
        final inCentralCross =
            (row >= 6 && row <= 8) || (col >= 6 && col <= 8);
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

    final layout = ClassicLudoBoardCoordinateFactory.create();
    for (var trackId = 0;
        trackId < ClassicLudoBoardDefinition.sharedTrackLength;
        trackId++) {
      final point = layout.forCell(trackId);
      final center = Offset(
        left + point.x * cell * grid,
        top + point.y * cell * grid,
      );
      final rect = Rect.fromCenter(center: center, width: cell, height: cell);
      canvas.drawRect(rect, trackPaint);
      canvas.drawRect(rect, linePaint);
    }

    for (final seat in ClassicLudoBoardDefinition.seats) {
      for (final cellId in seat.homeLaneCellIds) {
        final point = layout.forCell(cellId);
        final center = Offset(
          left + point.x * cell * grid,
          top + point.y * cell * grid,
        );
        final rect = Rect.fromCenter(center: center, width: cell, height: cell);
        canvas.drawRect(
          rect,
          Paint()..color = seat.color.withValues(alpha: 0.82),
        );
        canvas.drawRect(rect, linePaint);
      }
    }

    // Start squares are coloured; draw stars only on the four additional
    // provisional safe squares so the UI does not visually double-mark starts.
    const startIds = <int>{0, 13, 26, 39};
    for (final safeId
        in ClassicLudoBoardDefinition.provisionalSafeTrackCellIds) {
      if (startIds.contains(safeId)) continue;
      final point = layout.forCell(safeId);
      final center = Offset(
        left + point.x * cell * grid,
        top + point.y * cell * grid,
      );
      _drawStar(canvas, center, cell * 0.27);
    }

    final center = Offset(left + 7.5 * cell, top + 7.5 * cell);
    final centerPath = Path()
      ..moveTo(center.dx, center.dy - cell * 1.5)
      ..lineTo(center.dx + cell * 1.5, center.dy)
      ..lineTo(center.dx, center.dy + cell * 1.5)
      ..lineTo(center.dx - cell * 1.5, center.dy)
      ..close();
    canvas.drawPath(
      centerPath,
      Paint()
        ..color = LudoBoardPalette.gold.withValues(alpha: 0.48)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.45),
    );
    canvas.drawPath(
      centerPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFF4B8),
            Color(0xFFFFD700),
            Color(0xFFE4A900),
            Color(0xFF9D6500),
          ],
          stops: <double>[0, 0.34, 0.72, 1],
        ).createShader(centerPath.getBounds()),
    );
    canvas.drawPath(
      centerPath,
      Paint()
        ..color = const Color(0xFFFFF4C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.055,
    );
    // A small crowned-home emblem gives the finish a clear visual focal point.
    final crown = Path()
      ..moveTo(center.dx - cell * 0.68, center.dy - cell * 0.20)
      ..lineTo(center.dx - cell * 0.54, center.dy + cell * 0.34)
      ..lineTo(center.dx + cell * 0.54, center.dy + cell * 0.34)
      ..lineTo(center.dx + cell * 0.68, center.dy - cell * 0.20)
      ..lineTo(center.dx + cell * 0.32, center.dy + cell * 0.02)
      ..lineTo(center.dx, center.dy - cell * 0.42)
      ..lineTo(center.dx - cell * 0.32, center.dy + cell * 0.02)
      ..close();
    canvas.drawPath(
      crown,
      Paint()..color = const Color(0xFF6B4700),
    );
    canvas.drawPath(
      crown,
      Paint()
        ..color = const Color(0xFFFFF4C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.045,
    );

    for (final seat in ClassicLudoBoardDefinition.seats) {
      _drawStart(
        canvas,
        left,
        top,
        cell,
        seat.startMarker.column,
        seat.startMarker.row,
        seat.color,
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (var pointIndex = 0; pointIndex < 10; pointIndex++) {
      final angle = -math.pi / 2 + pointIndex * math.pi / 5;
      final pointRadius = pointIndex.isEven ? radius : radius * 0.43;
      final point = Offset(
        center.dx + math.cos(angle) * pointRadius,
        center.dy + math.sin(angle) * pointRadius,
      );
      if (pointIndex == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = LudoBoardPalette.gold);
    canvas.drawPath(
      path,
      Paint()
        ..color = LudoBoardPalette.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  void _drawHome(
    Canvas canvas,
    double left,
    double top,
    double cell,
    int col,
    int row,
    Color color,
  ) {
    final rect = Rect.fromLTWH(
      left + col * cell,
      top + row * cell,
      cell * 6,
      cell * 6,
    );
    // Premium enamel quadrant: a deep color field, subtle inner glow and
    // crisp metallic edge. The logical board coordinates remain unchanged.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.08)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.12)!,
            Color.lerp(color, Colors.black, 0.62)!,
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(cell * 0.06), Radius.circular(cell * 0.06)),
      Paint()
        ..color = color.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.055,
    );
    final inner = rect.deflate(cell * 1.05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(cell * 0.62)),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.16)!.withValues(alpha: 0.72),
            Color.lerp(color, Colors.black, 0.36)!.withValues(alpha: 0.78),
          ],
        ).createShader(inner),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner.deflate(cell * 0.035), Radius.circular(cell * 0.58)),
      Paint()
        ..color = LudoBoardPalette.cream.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.025,
    );
    for (final point in <Offset>[
      Offset(inner.left + inner.width * 0.3, inner.top + inner.height * 0.3),
      Offset(inner.right - inner.width * 0.3, inner.top + inner.height * 0.3),
      Offset(inner.left + inner.width * 0.3, inner.bottom - inner.height * 0.3),
      Offset(inner.right - inner.width * 0.3, inner.bottom - inner.height * 0.3),
    ]) {
      final radius = cell * 0.32;
      canvas.drawCircle(
        point.translate(0, cell * 0.06),
        radius * 1.04,
        Paint()
          ..color = LudoBoardPalette.black.withValues(alpha: 0.75)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.12),
      );
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.48),
            radius: 1.15,
            colors: <Color>[
              Color.lerp(color, Colors.white, 0.72)!,
              color,
              Color.lerp(color, Colors.black, 0.48)!,
            ],
            stops: const <double>[0, 0.42, 1],
          ).createShader(Rect.fromCircle(center: point, radius: radius)),
      );
      canvas.drawCircle(
        point.translate(-radius * 0.24, -radius * 0.34),
        radius * 0.23,
        Paint()..color = Colors.white.withValues(alpha: 0.78),
      );
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..color = LudoBoardPalette.cream.withValues(alpha: 0.86)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.055,
      );
    }
  }

  void _drawStart(
    Canvas canvas,
    double left,
    double top,
    double cell,
    int col,
    int row,
    Color color,
  ) {
    final rect = Rect.fromLTWH(
      left + col * cell,
      top + row * cell,
      cell,
      cell,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(cell * 0.12),
        Radius.circular(cell * 0.2),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant ClassicLudoBoardPainter oldDelegate) => false;
}
