/// Normalized rendering coordinates for a logical Ludo board.
///
/// This model intentionally does not invent the final 52-cell route. The
/// approved board fixture supplies coordinates keyed by logical cell ID; the
/// renderer converts normalized coordinates to pixels for the current canvas.
class BoardPoint {
  const BoardPoint({required this.x, required this.y});

  /// Normalized horizontal position in the inclusive range 0..1.
  final double x;

  /// Normalized vertical position in the inclusive range 0..1.
  final double y;

  bool get isValid => x.isFinite && y.isFinite && x >= 0 && x <= 1 && y >= 0 && y <= 1;

  /// Converts this point to pixels inside the given board size.
  BoardPixelPoint toPixels({required double width, required double height}) {
    if (!isValid) {
      throw StateError('Cannot convert an invalid normalized board point.');
    }
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      throw ArgumentError('Board width and height must be finite and positive.');
    }
    return BoardPixelPoint(x: x * width, y: y * height);
  }
}

class BoardPixelPoint {
  const BoardPixelPoint({required this.x, required this.y});

  final double x;
  final double y;
}

/// Pixel coordinates derived from a normalized board coordinate.
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
        throw ArgumentError('Cell ${entry.key} has an invalid normalized coordinate.');
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
}
