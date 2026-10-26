import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/board_coordinate_layout.dart';

void main() {
  group('BoardPoint', () {
    test('converts normalized coordinates to the available board size', () {
      const point = BoardPoint(x: 0.25, y: 0.75);
      final pixels = point.toPixels(width: 400, height: 600);

      expect(pixels.x, 100);
      expect(pixels.y, 450);
    });

    test('maps points into the centered square board inside a wide canvas', () {
      const point = BoardPoint(x: 0.5, y: 0.5);
      final pixels = point.toSquareBoardPixels(
        width: 400,
        height: 300,
        gridSize: 15,
      );

      expect(pixels.x, 200);
      expect(pixels.y, 150);
    });

    test('maps points into the centered square board inside a tall canvas', () {
      const point = BoardPoint(x: 0, y: 1);
      final pixels = point.toSquareBoardPixels(
        width: 300,
        height: 400,
        gridSize: 15,
      );

      expect(pixels.x, 0);
      expect(pixels.y, 350);
    });

    test('rejects invalid grid size for square-board conversion', () {
      expect(
        () => const BoardPoint(x: 0.5, y: 0.5).toSquareBoardPixels(
          width: 300,
          height: 300,
          gridSize: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-positive board dimensions', () {
      expect(
        () => const BoardPoint(x: 0.5, y: 0.5).toPixels(width: 0, height: 200),
        throwsArgumentError,
      );
    });

    test('rejects invalid normalized coordinates during conversion', () {
      const point = BoardPoint(x: 1.2, y: 0.5);
      expect(point.isValid, isFalse);
      expect(
        () => point.toPixels(width: 100, height: 100),
        throwsStateError,
      );
    });
  });

  group('BoardCoordinateLayout', () {
    test('stores an immutable copy of coordinate mappings', () {
      final input = <int, BoardPoint>{
        0: const BoardPoint(x: 0, y: 0),
        1: const BoardPoint(x: 1, y: 1),
      };
      final layout = BoardCoordinateLayout(input);
      input.clear();

      expect(layout.forCell(0).x, 0);
      expect(layout.forCell(1).y, 1);
      expect(() => layout.pointsByCell[2] = const BoardPoint(x: 0, y: 0),
          throwsUnsupportedError);
    });

    test('converts a logical cell to pixels', () {
      final layout = BoardCoordinateLayout(<int, BoardPoint>{
        12: const BoardPoint(x: 0.5, y: 0.25),
      });

      final result = layout.pixelForCell(cellId: 12, width: 300, height: 200);

      expect(result.x, 150);
      expect(result.y, 50);
    });

    test('hit-tests the nearest logical cell within the touch radius', () {
      final layout = BoardCoordinateLayout(<int, BoardPoint>{
        4: const BoardPoint(x: 0.25, y: 0.25),
        9: const BoardPoint(x: 0.75, y: 0.75),
      });

      expect(
        layout.hitTest(
          x: 102,
          y: 98,
          width: 400,
          height: 400,
          maxDistance: 10,
        ),
        4,
      );
      expect(
        layout.hitTest(
          x: 200,
          y: 200,
          width: 400,
          height: 400,
          maxDistance: 10,
        ),
        isNull,
      );
    });

    test('rejects invalid hit-test arguments', () {
      final layout = BoardCoordinateLayout(<int, BoardPoint>{
        0: const BoardPoint(x: 0.5, y: 0.5),
      });

      expect(
        () => layout.hitTest(
          x: double.nan,
          y: 1,
          width: 100,
          height: 100,
          maxDistance: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => layout.hitTest(
          x: 1,
          y: 1,
          width: 100,
          height: 100,
          maxDistance: -1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative logical cell IDs', () {
      expect(
        () => BoardCoordinateLayout(<int, BoardPoint>{
          -1: const BoardPoint(x: 0.5, y: 0.5),
        }),
        throwsArgumentError,
      );
    });

    test('rejects invalid normalized coordinates', () {
      expect(
        () => BoardCoordinateLayout(<int, BoardPoint>{
          0: const BoardPoint(x: double.nan, y: 0.5),
        }),
        throwsArgumentError,
      );
    });

    test('throws when a logical cell has no coordinate', () {
      final layout = BoardCoordinateLayout(<int, BoardPoint>{
        0: const BoardPoint(x: 0.5, y: 0.5),
      });

      expect(() => layout.forCell(7), throwsArgumentError);
    });
  });
}


