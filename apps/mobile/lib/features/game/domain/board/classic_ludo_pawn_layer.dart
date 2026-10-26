import 'package:flutter/material.dart';

import 'board_coordinate_layout.dart';

/// Presentation-only pawn marker positioned by a logical board cell ID.
class BoardPawnMarker {
  const BoardPawnMarker({
    required this.pawnId,
    required this.cellId,
    required this.color,
    this.pointOverride,
    this.selected = false,
  });

  final String pawnId;
  final int cellId;
  final Color color;
  final BoardPoint? pointOverride;
  final bool selected;
}

/// Draws pawn markers over the board using the same normalized coordinate map.
///
/// This is a renderer component only: it does not move pawns, validate turns,
/// or decide which moves are legal.
class ClassicLudoPawnLayer extends CustomPainter {
  ClassicLudoPawnLayer({
    required this.layout,
    required List<BoardPawnMarker> pawns,
    this.gridSize = 15,
  }) : pawns = List<BoardPawnMarker>.unmodifiable(pawns) {
    if (gridSize <= 0) {
      throw ArgumentError.value(gridSize, 'gridSize', 'Must be positive.');
    }
    final ids = this.pawns.map((pawn) => pawn.pawnId).toSet();
    if (ids.length != this.pawns.length ||
        this.pawns.any((pawn) => pawn.pawnId.trim().isEmpty)) {
      throw ArgumentError('Pawn IDs must be non-empty and unique.');
    }
    for (final pawn in this.pawns) {
      final point = pawn.pointOverride;
      if (point == null) {
        layout.forCell(pawn.cellId);
      } else if (!point.isValid) {
        throw ArgumentError('Pawn ${pawn.pawnId} has an invalid visual point.');
      }
    }
  }

  final BoardCoordinateLayout layout;
  final List<BoardPawnMarker> pawns;
  final int gridSize;

  static const List<Offset> _stackOffsets = <Offset>[
    Offset.zero,
    Offset(-0.19, -0.19),
    Offset(0.19, -0.19),
    Offset(-0.19, 0.19),
    Offset(0.19, 0.19),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cellSize = size.shortestSide / gridSize;
    final grouped = <String, List<BoardPawnMarker>>{};
    for (final pawn in pawns) {
      final point = pawn.pointOverride;
      final key = point == null
          ? 'cell:${pawn.cellId}'
          : 'point:${point.x.toStringAsFixed(5)},${point.y.toStringAsFixed(5)}';
      grouped.putIfAbsent(key, () => <BoardPawnMarker>[]).add(pawn);
    }

    for (final entry in grouped.entries) {
      final first = entry.value.first;
      final normalized = first.pointOverride;
      final point = normalized?.toSquareBoardPixels(
            width: size.width,
            height: size.height,
            gridSize: gridSize,
          ) ??
          layout.forCell(first.cellId).toSquareBoardPixels(
            width: size.width,
            height: size.height,
            gridSize: gridSize,
          );
      final occupants = entry.value;
      for (var index = 0; index < occupants.length; index++) {
        final pawn = occupants[index];
        final offset = occupants.length == 1
            ? Offset.zero
            : _stackOffsets[index % _stackOffsets.length] * cellSize;
        final center = Offset(point.x, point.y) + offset;
        final radius = cellSize * (occupants.length == 1 ? 0.34 : 0.25);

        canvas.drawCircle(
          center + Offset(0, radius * 0.18),
          radius * 1.04,
          Paint()..color = const Color(0x55000000),
        );
        if (pawn.selected) {
          canvas.drawCircle(
            center,
            radius * 1.28,
            Paint()
              ..color = const Color(0xFFFFD700)
              ..style = PaintingStyle.stroke
              ..strokeWidth = cellSize * 0.07,
          );
        }
        canvas.drawCircle(center, radius, Paint()..color = pawn.color);
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = const Color(0xFFFFF8E1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = cellSize * 0.055,
        );
        _drawHeart(canvas, center, radius * 0.54);
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size * 0.62)
      ..cubicTo(
        center.dx - size * 1.2,
        center.dy - size * 0.08,
        center.dx - size * 0.55,
        center.dy - size * 0.82,
        center.dx,
        center.dy - size * 0.32,
      )
      ..cubicTo(
        center.dx + size * 0.55,
        center.dy - size * 0.82,
        center.dx + size * 1.2,
        center.dy - size * 0.08,
        center.dx,
        center.dy + size * 0.62,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFF8E1));
  }

  @override
  bool shouldRepaint(covariant ClassicLudoPawnLayer oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.gridSize != gridSize ||
      oldDelegate.pawns.length != pawns.length ||
      !_samePawns(oldDelegate.pawns, pawns);

  bool _samePawns(List<BoardPawnMarker> a, List<BoardPawnMarker> b) {
    for (var index = 0; index < a.length; index++) {
      final left = a[index];
      final right = b[index];
      if (left.pawnId != right.pawnId ||
          left.cellId != right.cellId ||
          left.color != right.color ||
          left.selected != right.selected ||
          left.pointOverride?.x != right.pointOverride?.x ||
          left.pointOverride?.y != right.pointOverride?.y) {
        return false;
      }
    }
    return true;
  }
}
