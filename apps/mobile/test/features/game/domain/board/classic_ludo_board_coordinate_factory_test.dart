import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';

void main() {
  group('ClassicLudoBoardCoordinateFactory', () {
    test('provides 52 unique in-bounds shared-track cells', () {
      final route = ClassicLudoBoardCoordinateFactory.sharedTrack;
      expect(route, hasLength(52));
      expect(route.toSet(), hasLength(52));
      for (final cell in route) { expect(cell.isInsideBoard, isTrue); }
    });

    test('keeps consecutive route cells adjacent including wraparound', () {
      final route = ClassicLudoBoardCoordinateFactory.sharedTrack;
      for (var index = 0; index < route.length; index++) {
        final current = route[index];
        final next = route[(index + 1) % route.length];
        final dx = (current.column - next.column).abs();
        final dy = (current.row - next.row).abs();
        expect(dx <= 1 && dy <= 1 && dx + dy > 0, isTrue,
          reason: 'Consecutive route cells must touch');
      }
    });

    test('seat start markers align with their physical shared-track indexes', () {
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final routeCell =
            ClassicLudoBoardCoordinateFactory.sharedTrack[seat.provisionalTrackEntryIndex];
        expect(
          seat.startMarker.column,
          routeCell.column,
          reason: '${seat.id} start column',
        );
        expect(
          seat.startMarker.row,
          routeCell.row,
          reason: '${seat.id} start row',
        );
      }
    });

    test('builds normalized coordinates for track and all private lanes', () {
      final layout = ClassicLudoBoardCoordinateFactory.create();
      expect(layout.pointsByCell, hasLength(52 + 4 * 6));
      for (var cellId = 0; cellId < 52; cellId++) {
        expect(layout.pointsByCell.containsKey(cellId), isTrue);
      }
      for (final seat in ClassicLudoBoardDefinition.seats) {
        for (final cellId in seat.homeLaneCellIds) {
          expect(layout.pointsByCell.containsKey(cellId), isTrue);
          expect(layout.forCell(cellId).isValid, isTrue);
        }
      }
    });

    test('maps track cell centers consistently across pixel sizes', () {
      final layout = ClassicLudoBoardCoordinateFactory.create();
      final small = layout.pixelForCell(cellId: 0, width: 300, height: 300);
      final large = layout.pixelForCell(cellId: 0, width: 600, height: 600);
      expect(large.x, closeTo(small.x * 2, 0.000001));
      expect(large.y, closeTo(small.y * 2, 0.000001));
    });
  });
}
