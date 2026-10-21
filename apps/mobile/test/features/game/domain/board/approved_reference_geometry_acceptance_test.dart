import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';

void main() {
  group('Approved-reference geometry acceptance contract', () {
    // Independent golden coordinates for the route reviewed against the supplied
    // board mockup. This locks coordinate drift; on-device visual sign-off is
    // still required because the artwork is stylized rather than cell-annotated.
    const expectedTrack = <BoardGridCell>[
      BoardGridCell(column: 1, row: 6),
      BoardGridCell(column: 2, row: 6),
      BoardGridCell(column: 3, row: 6),
      BoardGridCell(column: 4, row: 6),
      BoardGridCell(column: 5, row: 6),
      BoardGridCell(column: 6, row: 5),
      BoardGridCell(column: 6, row: 4),
      BoardGridCell(column: 6, row: 3),
      BoardGridCell(column: 6, row: 2),
      BoardGridCell(column: 6, row: 1),
      BoardGridCell(column: 6, row: 0),
      BoardGridCell(column: 7, row: 0),
      BoardGridCell(column: 8, row: 0),
      BoardGridCell(column: 8, row: 1),
      BoardGridCell(column: 8, row: 2),
      BoardGridCell(column: 8, row: 3),
      BoardGridCell(column: 8, row: 4),
      BoardGridCell(column: 8, row: 5),
      BoardGridCell(column: 9, row: 6),
      BoardGridCell(column: 10, row: 6),
      BoardGridCell(column: 11, row: 6),
      BoardGridCell(column: 12, row: 6),
      BoardGridCell(column: 13, row: 6),
      BoardGridCell(column: 14, row: 6),
      BoardGridCell(column: 14, row: 7),
      BoardGridCell(column: 14, row: 8),
      BoardGridCell(column: 13, row: 8),
      BoardGridCell(column: 12, row: 8),
      BoardGridCell(column: 11, row: 8),
      BoardGridCell(column: 10, row: 8),
      BoardGridCell(column: 9, row: 8),
      BoardGridCell(column: 8, row: 9),
      BoardGridCell(column: 8, row: 10),
      BoardGridCell(column: 8, row: 11),
      BoardGridCell(column: 8, row: 12),
      BoardGridCell(column: 8, row: 13),
      BoardGridCell(column: 8, row: 14),
      BoardGridCell(column: 7, row: 14),
      BoardGridCell(column: 6, row: 14),
      BoardGridCell(column: 6, row: 13),
      BoardGridCell(column: 6, row: 12),
      BoardGridCell(column: 6, row: 11),
      BoardGridCell(column: 6, row: 10),
      BoardGridCell(column: 6, row: 9),
      BoardGridCell(column: 5, row: 8),
      BoardGridCell(column: 4, row: 8),
      BoardGridCell(column: 3, row: 8),
      BoardGridCell(column: 2, row: 8),
      BoardGridCell(column: 1, row: 8),
      BoardGridCell(column: 0, row: 8),
      BoardGridCell(column: 0, row: 7),
      BoardGridCell(column: 0, row: 6),
    ];

    test('all 52 shared-track coordinates match the independent reference fixture', () {
      expect(ClassicLudoBoardCoordinateFactory.sharedTrack, expectedTrack);
      expect(expectedTrack.toSet(), hasLength(52));
      expect(expectedTrack.every((cell) => cell.isInsideBoard), isTrue);
    });

    test('only the four reference corner links are diagonal', () {
      const expectedDiagonalIndexes = <int>[4, 17, 30, 43];
      expect(ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes, expectedDiagonalIndexes);
      expect(ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes, isEmpty);
      for (final index in expectedDiagonalIndexes) {
        final from = expectedTrack[index];
        final to = expectedTrack[(index + 1) % expectedTrack.length];
        expect((from.column - to.column).abs(), 1);
        expect((from.row - to.row).abs(), 1);
      }
    });

    test('entry cells and forward direction match all four quadrants', () {
      const expected = <String, List<BoardGridCell>>{
        'orange': <BoardGridCell>[
          BoardGridCell(column: 1, row: 6),
          BoardGridCell(column: 2, row: 6),
          BoardGridCell(column: 3, row: 6),
        ],
        'green': <BoardGridCell>[
          BoardGridCell(column: 8, row: 1),
          BoardGridCell(column: 8, row: 2),
          BoardGridCell(column: 8, row: 3),
        ],
        'magenta': <BoardGridCell>[
          BoardGridCell(column: 13, row: 8),
          BoardGridCell(column: 12, row: 8),
          BoardGridCell(column: 11, row: 8),
        ],
        'blue': <BoardGridCell>[
          BoardGridCell(column: 6, row: 13),
          BoardGridCell(column: 6, row: 12),
          BoardGridCell(column: 6, row: 11),
        ],
      };

      final paths = ClassicLudoBoardFixture.create();
      for (final entry in expected.entries) {
        final seat = ClassicLudoBoardDefinition.seatFor(entry.key);
        expect(seat.provisionalTrackEntryIndex, expectedTrack.indexOf(entry.value.first),
            reason: '${entry.key} entry index');
        final path = paths.forPlayer(entry.key);
        for (var progress = 0; progress < entry.value.length; progress++) {
          final physicalId = path.cellAtProgress(progress);
          expect(physicalId, isNotNull,
              reason: '${entry.key} progress $progress');
          expect(expectedTrack[physicalId!], entry.value[progress],
              reason: '${entry.key} forward direction at $progress');
        }
      }
    });

    test('each five-cell home lane matches its reference orientation', () {
      const expectedLanes = <String, List<BoardGridCell>>{
        'orange': <BoardGridCell>[
          BoardGridCell(column: 1, row: 7),
          BoardGridCell(column: 2, row: 7),
          BoardGridCell(column: 3, row: 7),
          BoardGridCell(column: 4, row: 7),
          BoardGridCell(column: 5, row: 7),
        ],
        'green': <BoardGridCell>[
          BoardGridCell(column: 7, row: 1),
          BoardGridCell(column: 7, row: 2),
          BoardGridCell(column: 7, row: 3),
          BoardGridCell(column: 7, row: 4),
          BoardGridCell(column: 7, row: 5),
        ],
        'blue': <BoardGridCell>[
          BoardGridCell(column: 7, row: 13),
          BoardGridCell(column: 7, row: 12),
          BoardGridCell(column: 7, row: 11),
          BoardGridCell(column: 7, row: 10),
          BoardGridCell(column: 7, row: 9),
        ],
        'magenta': <BoardGridCell>[
          BoardGridCell(column: 13, row: 7),
          BoardGridCell(column: 12, row: 7),
          BoardGridCell(column: 11, row: 7),
          BoardGridCell(column: 10, row: 7),
          BoardGridCell(column: 9, row: 7),
        ],
      };

      for (final entry in expectedLanes.entries) {
        expect(ClassicLudoBoardDefinition.seatFor(entry.key).homeLaneCells, entry.value,
            reason: '${entry.key} home-lane direction and cell centers');
      }
    });

    test('pawn coordinates resolve to exact cell centers on a square board', () {
      const boardSize = 300.0;
      const cellSize = boardSize / ClassicLudoBoardDefinition.gridSize;
      final layout = ClassicLudoBoardCoordinateFactory.create();

      for (var id = 0; id < expectedTrack.length; id++) {
        final cell = expectedTrack[id];
        final pixel = layout.pixelForCell(cellId: id, width: boardSize, height: boardSize);
        expect(pixel.x, closeTo((cell.column + 0.5) * cellSize, 1e-9),
            reason: 'track cell $id horizontal center');
        expect(pixel.y, closeTo((cell.row + 0.5) * cellSize, 1e-9),
            reason: 'track cell $id vertical center');
      }
    });

    test('visual topology remains unapproved until the reference is signed off', () {
      expect(ClassicLudoBoardDefinition.isVisualTopologyApproved, isFalse);
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
