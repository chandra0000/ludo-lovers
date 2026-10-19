import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';

void main() {
  group('Classic Ludo v1 visual-topology contract', () {
    test('the 52-cell route has only the four explicitly documented corner diagonals', () {
      const expectedDiagonalTransitions = <int, List<BoardGridCell>>{
        4: <BoardGridCell>[
          BoardGridCell(column: 5, row: 6),
          BoardGridCell(column: 6, row: 5),
        ],
        17: <BoardGridCell>[
          BoardGridCell(column: 8, row: 5),
          BoardGridCell(column: 9, row: 6),
        ],
        30: <BoardGridCell>[
          BoardGridCell(column: 9, row: 8),
          BoardGridCell(column: 8, row: 9),
        ],
        43: <BoardGridCell>[
          BoardGridCell(column: 6, row: 9),
          BoardGridCell(column: 5, row: 8),
        ],
      };

      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        expectedDiagonalTransitions.keys.toList()..sort(),
      );
      for (final entry in expectedDiagonalTransitions.entries) {
        expect(
          ClassicLudoBoardCoordinateFactory.sharedTrack[entry.key],
          entry.value.first,
          reason: 'v1 diagonal transition ${entry.key} has an unexpected source',
        );
        expect(
          ClassicLudoBoardCoordinateFactory.sharedTrack[
              (entry.key + 1) % ClassicLudoBoardDefinition.sharedTrackLength],
          entry.value.last,
          reason: 'v1 diagonal transition ${entry.key} has an unexpected destination',
        );
      }
      expect(ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes, isEmpty);
    });

    test('each player entry marker maps to its canonical physical track cell', () {
      const expectedEntries = <String, int>{
        'orange': 0,
        'green': 13,
        'magenta': 26,
        'blue': 39,
      };

      expect(ClassicLudoBoardDefinition.seats.map((seat) => seat.id).toSet(),
          expectedEntries.keys.toSet());
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final expectedIndex = expectedEntries[seat.id]!;
        expect(seat.provisionalTrackEntryIndex, expectedIndex,
            reason: '${seat.id} entry index drifted');
        expect(
          seat.startMarker,
          ClassicLudoBoardDefinition.sharedTrackCells[expectedIndex],
          reason: '${seat.id} visual start marker drifted from route',
        );
      }
    });

    test('the four star cells and four player starts agree with provisional safe IDs', () {
      const expectedSafeIds = <int>{0, 8, 13, 21, 26, 34, 39, 47};
      expect(ClassicLudoBoardDefinition.provisionalSafeTrackCellIds,
          expectedSafeIds);

      const expectedStarCells = <BoardGridCell>[
        BoardGridCell(column: 6, row: 2),
        BoardGridCell(column: 12, row: 6),
        BoardGridCell(column: 8, row: 12),
        BoardGridCell(column: 2, row: 8),
      ];
      final starCellIds = expectedSafeIds.difference(<int>{0, 13, 26, 39});
      expect(
        starCellIds.map(
          (id) => ClassicLudoBoardDefinition.sharedTrackCells[id],
        ),
        unorderedEquals(expectedStarCells),
      );
    });

    test('the route has 52 unique in-bounds cells and the finish stays outside the route', () {
      final track = ClassicLudoBoardDefinition.sharedTrackCells;
      expect(track, hasLength(ClassicLudoBoardDefinition.sharedTrackLength));
      expect(track.toSet(), hasLength(track.length));
      expect(track.every((cell) => cell.isInsideBoard), isTrue);
      expect(track, isNot(contains(ClassicLudoBoardDefinition.centerFinishCell)));
    });

    test('home lanes are five unique consecutive cells and never overlap shared track', () {
      final trackCells = ClassicLudoBoardDefinition.sharedTrackCells.toSet();
      final allLaneCells = <BoardGridCell>{};

      for (final seat in ClassicLudoBoardDefinition.seats) {
        expect(seat.homeLaneCells, hasLength(ClassicLudoBoardDefinition.homeLaneLength),
            reason: seat.id);
        for (var i = 0; i < seat.homeLaneCells.length; i++) {
          final cell = seat.homeLaneCells[i];
          expect(cell.isInsideBoard, isTrue, reason: '${seat.id} lane cell $i out of bounds');
          expect(trackCells.contains(cell), isFalse,
              reason: '${seat.id} lane overlaps shared track at $cell');
          expect(allLaneCells.add(cell), isTrue,
              reason: 'home lanes overlap at $cell');
          if (i > 0) {
            final previous = seat.homeLaneCells[i - 1];
            final distance = (previous.column - cell.column).abs() +
                (previous.row - cell.row).abs();
            expect(distance, 1, reason: '${seat.id} lane is not consecutive at $i');
          }
        }
      }
    });

    test('gameplay stays blocked until the visual topology is explicitly approved', () {
      expect(ClassicLudoBoardDefinition.isVisualTopologyApproved, isFalse);
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
