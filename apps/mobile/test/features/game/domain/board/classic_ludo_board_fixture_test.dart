import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';

void main() {
  group('ClassicLudoBoardFixture', () {
    test('keeps 52 physical loop cells but traverses 51 before five home cells', () {
      final board = ClassicLudoBoardFixture.create();

      expect(board.pathsByPlayer.length, 4);
      for (final route in board.pathsByPlayer.values) {
        expect(route.trackLength, 51);
        expect(route.homeLaneLength, 5);
        expect(route.mainTrackCells.length, 52);
        expect(route.mainTrackCells.toSet().length, 52);
        expect(route.homeLaneCells.length, 5);
      }
    });

    test('aligns provisional route entries with the board seat markers', () {
      final board = ClassicLudoBoardFixture.create();

      expect(board.forPlayer('orange').entryCell, 0);
      expect(board.forPlayer('green').entryCell, 13);
      expect(board.forPlayer('magenta').entryCell, 26);
      expect(board.forPlayer('blue').entryCell, 39);
    });

    test('keeps the same physical shared track across all player routes', () {
      final board = ClassicLudoBoardFixture.create();
      final reference = board.forPlayer('orange').mainTrackCells.toSet();

      for (final playerId in <String>['green', 'magenta', 'blue']) {
        expect(board.forPlayer(playerId).mainTrackCells.toSet(), reference);
      }
    });

    test('keeps home-lane IDs outside the shared track and unique', () {
      final board = ClassicLudoBoardFixture.create();
      final shared = board.forPlayer('orange').mainTrackCells.toSet();
      final allHomeCells = <int>{};

      for (final route in board.pathsByPlayer.values) {
        expect(route.homeLaneCells.any(shared.contains), isFalse);
        for (final cell in route.homeLaneCells) {
          expect(allHomeCells.add(cell), isTrue);
        }
      }
    });

    test('maps progress through the provisional entry and home lane', () {
      final board = ClassicLudoBoardFixture.create();
      final green = board.forPlayer('green');
      final blue = board.forPlayer('blue');

      expect(green.finishProgress, 56);
      expect(green.cellAtProgress(0), 13);
      expect(green.cellAtProgress(50), 11);
      expect(green.cellAtProgress(51), 220);
      expect(green.cellAtProgress(55), 224);
      expect(green.cellAtProgress(56), isNull);

      expect(blue.cellAtProgress(0), 39);
      expect(blue.cellAtProgress(50), 37);
      expect(blue.cellAtProgress(51), 210);
    });

    test('all four entries are distinct rotations of the same shared track', () {
      final board = ClassicLudoBoardFixture.create();
      final entries = board.pathsByPlayer.values.map((path) => path.entryCell).toSet();

      expect(entries, <int>{0, 13, 26, 39});
      expect(
        board.forPlayer('orange').mainTrackCells.toSet(),
        board.forPlayer('blue').mainTrackCells.toSet(),
      );
    });
  });
}
