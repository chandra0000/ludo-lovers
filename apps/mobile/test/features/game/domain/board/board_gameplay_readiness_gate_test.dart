import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';

void main() {
  group('classic board gameplay readiness gate', () {
    test('provisional board route cannot be treated as release-ready', () {
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });

    test('provisional route retains the known transition audit markers', () {

      // These diagonal transitions are known unresolved geometry, not
      // approved gameplay topology. Keep this assertion until the reference
      // board is reconciled and the acceptance tests are deliberately updated
      expect(ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes, <int>{4, 17, 30, 43});
    });
  });
}
