import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/ludo_board_paths.dart';

void main() {
  group('LudoPlayerPath', () {
    final path = LudoPlayerPath(
      playerId: 'orange',
      mainTrackCells: List<int>.generate(8, (index) => (index + 3) % 8),
      homeLaneCells: <int>[100, 101, 102],
      trackLength: 8,
    );

    test('uses first main-track cell as entry cell', () {
      expect(path.entryCell, 3);
    });

    test('maps player-relative progress to main-track cells', () {
      expect(path.cellAtProgress(0), 3);
      expect(path.cellAtProgress(1), 4);
      expect(path.cellAtProgress(5), 0);
    });

    test('maps progress after the shared track into the home lane', () {
      expect(path.cellAtProgress(8), 100);
      expect(path.cellAtProgress(9), 101);
      expect(path.cellAtProgress(10), 102);
    });

    test('returns null beyond the represented path', () {
      expect(path.cellAtProgress(path.finishProgress + 1), isNull);
    });

    test('accepts exact finish progress', () {
      expect(
        path.canAdvance(
          currentProgress: path.finishProgress - 2,
          diceValue: 2,
          requireExactFinish: true,
        ),
        isTrue,
      );
    });

    test('rejects overshoot when exact finish is required', () {
      expect(
        path.canAdvance(
          currentProgress: path.finishProgress - 2,
          diceValue: 3,
          requireExactFinish: true,
        ),
        isFalse,
      );
    });

    test('validates unique main-track cells', () {
      expect(
        () => LudoPlayerPath(
          playerId: 'bad',
          mainTrackCells: <int>[0, 1, 2, 3, 4, 5, 6, 6],
          homeLaneCells: <int>[100, 101],
          trackLength: 8,
        ),
        throwsArgumentError,
      );
    });
  });


  test('rejects duplicate player routes instead of silently replacing one', () {
    final route = LudoPlayerPath(
      playerId: 'orange',
      mainTrackCells: List<int>.generate(8, (i) => i),
      homeLaneCells: <int>[100, 101],
      trackLength: 8,
    );
    expect(
      () => LudoBoardPaths(<LudoPlayerPath>[
        route,
        LudoPlayerPath(
          playerId: 'orange',
          mainTrackCells: List<int>.generate(8, (i) => (i + 1) % 8),
          homeLaneCells: <int>[110, 111],
          trackLength: 8,
        ),
      ]),
      throwsArgumentError,
    );
  });

  test('rejects home lanes that overlap the shared track or each other', () {
    final orange = LudoPlayerPath(
      playerId: 'orange',
      mainTrackCells: List<int>.generate(8, (i) => i),
      homeLaneCells: <int>[100, 101],
      trackLength: 8,
    );
    expect(
      () => LudoBoardPaths(<LudoPlayerPath>[
        orange,
        LudoPlayerPath(
          playerId: 'blue',
          mainTrackCells: List<int>.generate(8, (i) => (i + 2) % 8),
          homeLaneCells: <int>[100, 111],
          trackLength: 8,
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => LudoBoardPaths(<LudoPlayerPath>[
        orange,
        LudoPlayerPath(
          playerId: 'blue',
          mainTrackCells: List<int>.generate(8, (i) => (i + 2) % 8),
          homeLaneCells: <int>[2, 111],
          trackLength: 8,
        ),
      ]),
      throwsArgumentError,
    );
  });

  test('LudoBoardPaths looks up each player route', () {
    final paths = LudoBoardPaths(<LudoPlayerPath>[
      LudoPlayerPath(
        playerId: 'orange',
        mainTrackCells: List<int>.generate(8, (i) => i),
        homeLaneCells: <int>[100, 101],
        trackLength: 8,
      ),
      LudoPlayerPath(
        playerId: 'green',
        mainTrackCells: List<int>.generate(8, (i) => (i + 2) % 8),
        homeLaneCells: <int>[110, 111],
        trackLength: 8,
      ),
    ]);

    expect(paths.forPlayer('green').entryCell, 2);
    expect(() => paths.forPlayer('missing'), throwsArgumentError);
  });
}
