import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';

void main() {
  group('Classic Ludo v1 visual-topology contract', () {
    test('the 52-cell route identifies all four diagonal transitions as blockers', () {
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
      expect(
        ClassicLudoBoardCoordinateFactory.referenceCornerConnectorIndexes,
        <int>{4, 17, 30, 43},
      );
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(
        ClassicLudoBoardCoordinateFactory.unmappedTransitionIndexes,
        isEmpty,
        reason: 'Known corner connectors must not be confused with accidental jumps.',
      );
      expect(
        ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes,
        isEmpty,
      );
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
      const track = ClassicLudoBoardDefinition.sharedTrackCells;
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


    test('audits every shared-track edge, including the 51-to-0 wrap', () {
      const track = ClassicLudoBoardDefinition.sharedTrackCells;
      expect(track, hasLength(52));

      const diagonalEdges = <int>{4, 17, 30, 43};
      for (var index = 0; index < track.length; index++) {
        final from = track[index];
        final to = track[(index + 1) % track.length];
        final dx = (from.column - to.column).abs();
        final dy = (from.row - to.row).abs();
        final isOrthogonal = dx + dy == 1;
        final isDocumentedCornerConnector =
            diagonalEdges.contains(index) && dx == 1 && dy == 1;

        expect(
          isOrthogonal || isDocumentedCornerConnector,
          isTrue,
          reason: 'Unmapped route edge $index -> ${(index + 1) % track.length}: '
              '($from) -> ($to)',
        );
      }

      final last = track[51];
      final first = track[0];
      expect(last, const BoardGridCell(column: 0, row: 6));
      expect(first, const BoardGridCell(column: 1, row: 6));
      expect((last.column - first.column).abs() +
          (last.row - first.row).abs(), 1,
          reason: 'The shared route must wrap continuously from 51 to 0.');
    });

    test('home-lane branch and five movement cells are explicit for every seat', () {
      const track = ClassicLudoBoardDefinition.sharedTrackCells;
      for (final seat in ClassicLudoBoardDefinition.seats) {
        final approachIndex =
            (seat.provisionalTrackEntryIndex + 50) % track.length;
        final approach = track[approachIndex];
        final firstLane = seat.homeLaneCells.first;
        final dx = (approach.column - firstLane.column).abs();
        final dy = (approach.row - firstLane.row).abs();

        expect(dx <= 1 && dy <= 1 && dx + dy > 0, isTrue,
            reason: '${seat.id} lane must branch from its final main-track cell');
        expect(seat.homeLaneCells, hasLength(5), reason: seat.id);
        for (var step = 1; step < seat.homeLaneCells.length; step++) {
          final previous = seat.homeLaneCells[step - 1];
          final current = seat.homeLaneCells[step];
          expect((previous.column - current.column).abs() +
              (previous.row - current.row).abs(), 1,
              reason: '${seat.id} home-lane movement step $step');
        }
      }
    });

    test('documented corner connectors do not silently approve gameplay', () {
      expect(ClassicLudoBoardCoordinateFactory.isOrthogonallyContinuous, isFalse,
          reason: 'The four diagonal connectors remain explicit review signals.');
      expect(ClassicLudoBoardCoordinateFactory.unmappedTransitionIndexes, isEmpty);
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse,
          reason: 'Visual approval remains a separate release gate.');
    });

    test('gameplay stays blocked until the visual topology is explicitly approved', () {
      expect(ClassicLudoBoardDefinition.isVisualTopologyApproved, isFalse);
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
    test('locks the reference quadrant palette and five-cell lane proportions', () {
      const expectedSeats = <String, BoardQuadrant>{
        'orange': BoardQuadrant.topLeft,
        'green': BoardQuadrant.topRight,
        'blue': BoardQuadrant.bottomLeft,
        'magenta': BoardQuadrant.bottomRight,
      };
      const expectedColors = <String, int>{
        'orange': 0xFFFF8928,
        'green': 0xFF33FF28,
        'blue': 0xFF289EFF,
        'magenta': 0xFFF428FF,
      };

      expect(ClassicLudoBoardDefinition.gridSize, 15);
      expect(ClassicLudoBoardDefinition.centerFinishCell,
          const BoardGridCell(column: 7, row: 7));
      expect(ClassicLudoBoardDefinition.homeLaneLength, 5);
      for (final seat in ClassicLudoBoardDefinition.seats) {
        expect(seat.quadrant, expectedSeats[seat.id],
            reason: '${seat.id} must remain in its reference quadrant');
        expect(seat.color.toARGB32(), expectedColors[seat.id],
            reason: '${seat.id} must use the exact Ludo Lovers brand color');
        expect(seat.homeLaneCells, hasLength(5));
        expect(seat.homeLaneCells.toSet(), hasLength(5));
      }
      expect(ClassicLudoBoardDefinition.isVisualTopologyApproved, isFalse,
          reason: 'A geometry contract is not a substitute for visual sign-off.');
    });

  });
}
