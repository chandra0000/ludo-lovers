import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_geometry_audit.dart';

void main() {
  group('ClassicLudoBoardGeometryAudit', () {
    test('provisional board fixture is internally consistent', () {
      expect(
        ClassicLudoBoardGeometryAudit.inspect(),
        isEmpty,
      );
      expect(
        ClassicLudoBoardGeometryAudit.isStructurallyConsistent,
        isTrue,
      );
    });

    test('structural consistency is not the same as gameplay approval', () {
      // The track still has provisional diagonal transitions and needs visual
      // review. A structural audit must not silently approve it for gameplay.
      expect(
        ClassicLudoBoardGeometryAudit.isStructurallyConsistent,
        isTrue,
      );
      expect(
        ClassicLudoBoardCoordinateFactory.isGameplayReady,
        isFalse,
      );
      expect(
        ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes,
        <int>[4, 17, 30, 43],
      );
    });
  });
}
