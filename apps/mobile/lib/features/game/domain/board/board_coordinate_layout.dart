import 'package:flutter/material.dart';

/// Normalized rendering coordinates for a logical Ludo board.
///
/// The approved board fixture supplies coordinates keyed by logical cell ID.
/// This model converts normalized positions to pixels and contains no game rules.
class BoardPoint {
  const BoardPoint({required this.x, required this.y});

  final double x;
  final double y;

  bool get isValid =>
      x.isFinite && y.isFinite && x >= 0 && x <= 1 && y >= 0 && y <= 1;

  BoardPixelPoint toPixels({required double width, required double height}) {
    if (!isValid) {
      throw StateError('Cannot convert an invalid normalized board point.');
    }
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      throw ArgumentError('Board width and height must be finite and positive.');
    }
    return BoardPixelPoint(x: x * width, y: y * height);
  }

  /// Converts a normalized point using the same centered square viewport as
  /// [ClassicLudoBoardPainter]. This keeps pawn overlays aligned when their
  /// CustomPaint canvas is wider or taller than the actual square board.
  BoardPixelPoint toSquareBoardPixels({
    required double width,
    required double height,
    required int gridSize,
  }) {
    if (!isValid) {
      throw StateError('Cannot convert an invalid normalized board point.');
    }
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      throw ArgumentError('Board width and height must be finite and positive.');
    }
    if (gridSize <= 0) {
      throw ArgumentError.value(gridSize, 'gridSize', 'Must be positive.');
    }
    final side = width < height ? width : height;
    final left = (width - side) / 2;
    final top = (height - side) / 2;
    return BoardPixelPoint(
      x: left + x * side,
      y: top + y * side,
    );
  }
}

class BoardPixelPoint {
  const BoardPixelPoint({required this.x, required this.y});

  final double x;
  final double y;
}

/// Maps logical cell IDs to normalized positions, independent of screen size.
class BoardCoordinateLayout {
  BoardCoordinateLayout(Map<int, BoardPoint> points)
      : pointsByCell = Map<int, BoardPoint>.unmodifiable(points) {
    if (pointsByCell.isEmpty) {
      throw ArgumentError('At least one board coordinate is required.');
    }
    for (final entry in pointsByCell.entries) {
      if (entry.key < 0) {
        throw ArgumentError('Logical cell IDs must be non-negative.');
      }
      if (!entry.value.isValid) {
        throw ArgumentError(
          'Cell ${entry.key} has an invalid normalized coordinate.',
        );
      }
    }
  }

  final Map<int, BoardPoint> pointsByCell;

  BoardPoint forCell(int cellId) {
    final point = pointsByCell[cellId];
    if (point == null) {
      throw ArgumentError('No coordinate defined for logical cell $cellId.');
    }
    return point;
  }

  BoardPixelPoint pixelForCell({
    required int cellId,
    required double width,
    required double height,
  }) =>
      forCell(cellId).toPixels(width: width, height: height);

  /// Returns the nearest logical cell whose center is within [maxDistance].
  ///
  /// Coordinates are measured in pixels relative to the board's own canvas.
  /// A null result means the touch is too far from every registered cell.
  /// This helper does not decide whether a pawn may move to the selected cell.
  int? hitTest({
    required double x,
    required double y,
    required double width,
    required double height,
    required double maxDistance,
  }) {
    if (!x.isFinite || !y.isFinite) {
      throw ArgumentError('Touch coordinates must be finite.');
    }
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      throw ArgumentError('Board width and height must be finite and positive.');
    }
    if (!maxDistance.isFinite || maxDistance < 0) {
      throw ArgumentError('Hit-test distance must be finite and non-negative.');
    }

    final maxDistanceSquared = maxDistance * maxDistance;
    int? nearestCellId;
    var nearestDistanceSquared = double.infinity;

    for (final entry in pointsByCell.entries) {
      final pixel = entry.value.toPixels(width: width, height: height);
      final dx = pixel.x - x;
      final dy = pixel.y - y;
      final distanceSquared = dx * dx + dy * dy;
      if (distanceSquared < nearestDistanceSquared) {
        nearestDistanceSquared = distanceSquared;
        nearestCellId = entry.key;
      }
    }

    if (nearestDistanceSquared > maxDistanceSquared) return null;
    return nearestCellId;
  }
}

/// The fixed Ludo Lovers palette. Keep all game rendering tied to these values.
class LudoBoardPalette {
  const LudoBoardPalette._();

  static const Color orange = Color(0xFFFF8928);
  static const Color green = Color(0xFF33FF28);
  static const Color blue = Color(0xFF289EFF);
  static const Color magenta = Color(0xFFF428FF);
  static const Color gold = Color(0xFFFFD700);
  static const Color red = Color(0xFFFF3830);
  static const Color black = Color(0xFF080B0B);
  static const Color cream = Color(0xFFFFF8E1);

  static const List<Color> playerColors = <Color>[
    orange,
    green,
    blue,
    magenta,
  ];
}
