import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/board_pawn_layout.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/engine/ludo_path_movement.dart';

void main() {
  group('BoardPawnLayout', () {
    late BoardPawnLayout pawnLayout;

    setUp(() {
      pawnLayout = BoardPawnLayout.classic();
    });

    test('maps each player to its provisional track entry', () {
      final orange = pawnLayout.resolve(
        playerId: 'orange',
        pawnId: 'orange-1',
        position: const PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 0,
        ),
      );
      final green = pawnLayout.resolve(
        playerId: 'green',
        pawnId: 'green-1',
        position: const PawnRoutePosition(
          section: PawnRouteSection.mainTrack,
          progress: 0,
        ),
      );

      expect(orange.point.x, pawnLayout.layout.forCell(0).x);
      expect(orange.point.y, pawnLayout.layout.forCell(0).y);
      expect(green.point.x, pawnLayout.layout.forCell(13).x);
      expect(green.point.y, pawnLayout.layout.forCell(13).y);
    });

    test('maps every shared-track progress to the physical 52-cell loop', () {
      for (final seat in ClassicLudoBoardDefinition.seats) {
        for (var progress = 0;
            progress < ClassicLudoBoardDefinition.playerTrackLength;
            progress++) {
          final expectedCell =
              (seat.provisionalTrackEntryIndex + progress) %
              ClassicLudoBoardDefinition.sharedTrackLength;
          final pawn = pawnLayout.resolve(
            playerId: seat.id,
            pawnId: '${seat.id}-progress-$progress',
            position: PawnRoutePosition(
              section: PawnRouteSection.mainTrack,
              progress: progress,
            ),
          );

          expect(
            pawn.point.x,
            pawnLayout.layout.forCell(expectedCell).x,
            reason: '${seat.id} at progress $progress: x coordinate',
          );
          expect(
            pawn.point.y,
            pawnLayout.layout.forCell(expectedCell).y,
            reason: '${seat.id} at progress $progress: y coordinate',
          );
        }
      }
    });

    test('maps home-lane progress to the player lane', () {
      final position = pawnLayout.resolve(
        playerId: 'green',
        pawnId: 'green-1',
        position: const PawnRoutePosition(
          section: PawnRouteSection.homeLane,
          progress: 51,
        ),
      );

      expect(position.point.x, pawnLayout.layout.forCell(220).x);
      expect(position.point.y, pawnLayout.layout.forCell(220).y);
    });

    test('places yard pawns in four distinct slots inside their quadrant', () {
      final points = <String>{};
      for (var slot = 0; slot < 4; slot++) {
        final pawn = pawnLayout.resolve(
          playerId: 'orange',
          pawnId: 'orange-$slot',
          position: const PawnRoutePosition(section: PawnRouteSection.yard),
          yardSlot: slot,
        );
        expect(pawn.point.isValid, isTrue);
        points.add('${pawn.point.x},${pawn.point.y}');
      }
      expect(points, hasLength(4));
    });

    test('places finished pawns at the board center', () {
      final pawn = pawnLayout.resolve(
        playerId: 'blue',
        pawnId: 'blue-1',
        position: const PawnRoutePosition(
          section: PawnRouteSection.finished,
          progress: 56,
        ),
      );

      expect(
        pawn.point.x,
        (ClassicLudoBoardDefinition.centerFinishCell.column + 0.5) /
            ClassicLudoBoardDefinition.gridSize,
      );
      expect(
        pawn.point.y,
        (ClassicLudoBoardDefinition.centerFinishCell.row + 0.5) /
            ClassicLudoBoardDefinition.gridSize,
      );
    });

    test('rejects invalid yard slots, negative stack index and invalid progress', () {
      expect(
        () => pawnLayout.resolve(
          playerId: 'orange',
          pawnId: 'orange-1',
          position: const PawnRoutePosition(section: PawnRouteSection.yard),
          yardSlot: 4,
        ),
        throwsArgumentError,
      );
      expect(
        () => pawnLayout.resolve(
          playerId: 'orange',
          pawnId: 'orange-1',
          position: const PawnRoutePosition(section: PawnRouteSection.yard),
          stackIndex: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => pawnLayout.resolve(
          playerId: 'orange',
          pawnId: 'orange-1',
          position: const PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('exposes that the provisional route is not yet gameplay-ready', () {
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    });
  });
}
