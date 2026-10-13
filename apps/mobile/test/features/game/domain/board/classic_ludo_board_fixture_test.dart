import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_fixture.dart';
import 'package:ludo_lovers/features/game/domain/board/ludo_board_paths.dart';

void main() {
  group('ClassicLudoBoardFixture', () {
    test('defines a standard four-player route with 52 shared-track cells', () {
      final board = ClassicLudoBoardFixture.create();

      expect(board.pathsByPlayer.length, 4);
      for (final route in board.pathsByPlayer.values) {
        expect(route.trackLength, 52);
        expect(route.homeLaneLength, 6);
        expect(route.mainTrackCells.length, 52);
        expect(route.mainTrackCells.toSet().length, 52);
        expect(route.homeLaneCells.length, 6);
      }
    });

    test('ensures each player route starts from the expected entry offset', () {
      final board = ClassicLudoBoardFixture.create();

      expect(board.forPlayer('orange').entryCell, 0);
      expect(board.forPlayer('blue').entryCell, 13);
      expect(board.forPlayer('green').entryCell, 26);
      expect(board.forPlayer('magenta').entryCell, 39);
    });

    test('keeps shared-track cells consistent across player routes', () {
      final board = ClassicLudoBoardFixture.create();
      final reference = board.forPlayer('orange').mainTrackCells.toSet();

      for (final playerId in <String>['blue', 'green', 'magenta']) {
        final route = board.forPlayer(playerId).mainTrackCells.toSet();
        expect(route, reference);
      }
    });

    test('places home-lane cells outside the shared track and keeps them unique', () {
      final board = ClassicLudoBoardFixture.create();
      final shared = board.forPlayer('orange').mainTrackCells.toSet();
      final allHomeCells = <int>{};

      for (final entry in board.pathsByPlayer.values) {
        expect(entry.homeLaneCells.any(shared.contains), isFalse);
        for (final cell in entry.homeLaneCells) {
          expect(allHomeCells.add(cell), isTrue);
        }
      }
    });

    test('allows progress checks using route length and private lane mapping', () {
      final board = ClassicLudoBoardFixture.create();
      final path = board.forPlayer('blue');

      expect(path.finishProgress, 58);
      expect(path.cellAtProgress(0), 13);
      expect(path.cellAtProgress(51), 12);
      expect(path.cellAtProgress(52), 210);
      expect(path.cellAtProgress(57), 215);
      expect(path.cellAtProgress(58), isNull);
    });
  });

  group('LudoBoardPaths', () {
    test('rejects mismatched shared-track routes', () {
      expect(
        () => LudoBoardPaths(<LudoPlayerPath>[
          LudoPlayerPath(
            playerId: 'orange',
            mainTrackCells: List<int>.generate(52, (index) => index),
            homeLaneCells: List<int>.generate(6, (index) => 200 + index),
            trackLength: 52,
          ),
          LudoPlayerPath(
            playerId: 'blue',
            mainTrackCells: List<int>.generate(52, (index) => (index + 2) % 52),
            homeLaneCells: List<int>.generate(6, (index) => 210 + index),
            trackLength: 52,
          ),
          LudoPlayerPath(
            playerId: 'green',
            mainTrackCells: List<int>.generate(52, (index) => (index + 26) % 52),
            homeLaneCells: List<int>.generate(6, (index) => 220 + index),
            trackLength: 52,
          ),
          LudoPlayerPath(
            playerId: 'magenta',
            mainTrackCells: List<int>.generate(52, (index) => (index + 39) % 52),
            homeLaneCells: List<int>.generate(6, (index) => 230 + index),
            trackLength: 52,
          ),
        ]),
        throwsArgumentError,
      );
    });
  });
}
