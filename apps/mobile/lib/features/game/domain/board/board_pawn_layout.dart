import '../board/board_coordinate_layout.dart';
import '../board/classic_ludo_board_coordinate_factory.dart';
import '../board/classic_ludo_board_definition.dart';
import '../engine/ludo_path_movement.dart';

/// Presentation-only location for a pawn. It contains no move legality rules.
class BoardPawnVisualPosition {
  const BoardPawnVisualPosition({
    required this.playerId,
    required this.pawnId,
    required this.point,
    required this.state,
    this.stackIndex = 0,
  });

  final String playerId;
  final String pawnId;
  final BoardPoint point;
  final PawnRouteSection state;

  /// Stable index used to fan out pawns sharing one cell.
  final int stackIndex;
}

/// Maps local-engine pawn positions to normalized board presentation points.
///
/// Yard and finished positions are intentionally handled here rather than by
/// the route resolver, because they do not occupy numbered track cells.
class BoardPawnLayout {
  const BoardPawnLayout({
    required this.layout,
  });

  factory BoardPawnLayout.classic() {
    return BoardPawnLayout(
      layout: ClassicLudoBoardCoordinateFactory.create(),
    );
  }

  final BoardCoordinateLayout layout;

  BoardPawnVisualPosition resolve({
    required String playerId,
    required String pawnId,
    required PawnRoutePosition position,
    int yardSlot = 0,
    int stackIndex = 0,
  }) {
    final seat = ClassicLudoBoardDefinition.seatFor(playerId);
    if (stackIndex < 0) {
      throw ArgumentError.value(stackIndex, 'stackIndex', 'Must be non-negative');
    }

    switch (position.section) {
      case PawnRouteSection.yard:
        if (yardSlot < 0 || yardSlot > 3) {
          throw ArgumentError.value(yardSlot, 'yardSlot', 'Must be between 0 and 3');
        }
        final columnOffset = yardSlot.isEven ? 2.22 : 3.78;
        final rowOffset = yardSlot < 2 ? 2.22 : 3.78;
        return BoardPawnVisualPosition(
          playerId: playerId,
          pawnId: pawnId,
          point: BoardPoint(
            x: (seat.yardColumn + columnOffset) /
                ClassicLudoBoardDefinition.gridSize,
            y: (seat.yardRow + rowOffset) /
                ClassicLudoBoardDefinition.gridSize,
          ),
          state: position.section,
          stackIndex: stackIndex,
        );
      case PawnRouteSection.mainTrack:
      case PawnRouteSection.homeLane:
        final progress = position.progress;
        if (progress == null || progress < 0) {
          throw ArgumentError('On-board pawns require non-negative progress.');
        }
        const trackLength = ClassicLudoBoardDefinition.playerTrackLength;
        if (position.section == PawnRouteSection.mainTrack &&
            progress >= trackLength) {
          throw ArgumentError('Main-track progress is outside the shared track.');
        }
        if (position.section == PawnRouteSection.homeLane &&
            progress < trackLength) {
          throw ArgumentError('Home-lane progress is still on the shared track.');
        }
        // The physical loop has 52 cells, but player progress traverses only
        // 51 before turning directly into the private lane. Keep modulo based
        // on the physical loop length so player-relative routing stays aligned.
        final pathIndex = position.section == PawnRouteSection.mainTrack
            ? (seat.provisionalTrackEntryIndex + progress) %
                ClassicLudoBoardDefinition.sharedTrackLength
            : seat.homeLaneStartCellId +
                (progress - trackLength);
        final point = layout.pointsByCell[pathIndex];
        if (point == null) {
          throw StateError('No board coordinate exists for pawn cell $pathIndex.');
        }
        return BoardPawnVisualPosition(
          playerId: playerId,
          pawnId: pawnId,
          point: point,
          state: position.section,
          stackIndex: stackIndex,
        );
      case PawnRouteSection.finished:
        return BoardPawnVisualPosition(
          playerId: playerId,
          pawnId: pawnId,
          point: BoardPoint(
            x: (ClassicLudoBoardDefinition.centerFinishCell.column + 0.5) /
                ClassicLudoBoardDefinition.gridSize,
            y: (ClassicLudoBoardDefinition.centerFinishCell.row + 0.5) /
                ClassicLudoBoardDefinition.gridSize,
          ),
          state: position.section,
          stackIndex: stackIndex,
        );
    }
  }
}
