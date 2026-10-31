import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_topology.dart';

void main() {
  group('Classic Ludo orthogonal board topology', () {
    test('reports all four diagonal shared-track edges by exact index', () {
      expect(
        ClassicLudoBoardTopology.nonOrthogonalEdgeIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(
        ClassicLudoBoardCoordinateFactory.describeTransition(4),
        '4 (5,6) → 5 (6,5)',
      );
      expect(
        ClassicLudoBoardCoordinateFactory.describeTransition(17),
        '17 (8,5) → 18 (9,6)',
      );
      expect(
        ClassicLudoBoardCoordinateFactory.describeTransition(30),
        '30 (9,8) → 31 (8,9)',
      );
      expect(
        ClassicLudoBoardCoordinateFactory.describeTransition(43),
        '43 (6,9) → 44 (5,8)',
      );
    });

    test('keeps the 51 to 0 wrap edge orthogonally adjacent', () {
      const last = BoardGridCell(column: 0, row: 6);
      const first = BoardGridCell(column: 1, row: 6);
      expect(last, const BoardGridCell(column: 0, row: 6));
      expect(first, const BoardGridCell(column: 1, row: 6));
      expect(
        (last.column - first.column).abs() +
            (last.row - first.row).abs(),
        1,
      );
      expect(
        ClassicLudoBoardTopology.nonOrthogonalEdgeIndexes,
        isNot(contains(51)),
      );
    });

    test('explains the checkerboard parity conflict in all four 13-step seat intervals', () {
      final seats = ClassicLudoBoardDefinition.seats.toList()
        ..sort((a, b) => a.provisionalTrackEntryIndex
            .compareTo(b.provisionalTrackEntryIndex));

      expect(
        seats.map((seat) => seat.provisionalTrackEntryIndex),
        <int>[0, 13, 26, 39],
      );
      expect(
        seats.map((seat) =>
            (seat.startMarker.column + seat.startMarker.row).isEven),
        everyElement(isFalse),
        reason: 'All four currently defined entry markers have odd checkerboard parity.',
      );
      expect(ClassicLudoBoardTopology.entryParityConflicts, hasLength(4));
      expect(
        ClassicLudoBoardTopology.entryParityConflicts,
        everyElement(contains('13 orthogonal steps require opposite parity')),
      );
    });

    test('does not certify the current candidate as an orthogonal topology', () {
      expect(ClassicLudoBoardTopology.isOrthogonalCycle, isFalse);
      expect(ClassicLudoBoardTopology.hasCompatibleEntryParity, isFalse);
      expect(ClassicLudoBoardTopology.isOrthogonalTopologyValid, isFalse);
      expect(ClassicLudoBoardCoordinateFactory.isOrthogonallyContinuous, isFalse);
      expect(ClassicLudoBoardCoordinateFactory.hasCompatibleEntryParity, isFalse);
      expect(ClassicLudoBoardCoordinateFactory.isOrthogonalTopologyValid, isFalse);
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
      expect(ClassicLudoBoardCoordinateFactory.topologyBlockers, isNotEmpty);
    });

    test('does not silently move entry markers or alter the brand board definition', () {
      const expected = <String, (int, BoardGridCell)>{
        'orange': (0, BoardGridCell(column: 1, row: 6)),
        'green': (13, BoardGridCell(column: 8, row: 1)),
        'magenta': (26, BoardGridCell(column: 13, row: 8)),
        'blue': (39, BoardGridCell(column: 6, row: 13)),
      };
      for (final seat in ClassicLudoBoardDefinition.seats) {
        expect(
          (seat.provisionalTrackEntryIndex, seat.startMarker),
          expected[seat.id],
          reason: 'Do not guess a new entry coordinate without approved reference evidence.',
        );
      }
    });
  });
}
