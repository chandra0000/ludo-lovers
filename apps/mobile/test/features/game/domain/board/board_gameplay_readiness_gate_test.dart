import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';

void main() {
  group('classic board gameplay readiness gate', () {
    test('provisional board route cannot be treated as release-ready', () {
      expect(
        ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });

    test('provisional route retains the known transition audit markers', () {

      // These diagonal links are currently known release blockers under the
      // orthogonal-continuity contract.
      expect(ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes, <int>[4, 17, 30, 43]);
    });
  });
}
