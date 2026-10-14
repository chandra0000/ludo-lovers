import '../board/board_coordinate_layout.dart';
import '../board/ludo_board_paths.dart';
import 'ludo_path_movement.dart';

/// Converts a logical pawn route position into a renderer cell ID.
///
/// This adapter does not decide whether a move is legal and does not approve
/// provisional board geometry. It only projects a stored position through the
/// supplied player route and checks that the renderer has a point.
class BoardPawnPositionResolver {
  const BoardPawnPositionResolver({
    required this.paths,
    required this.layout,
  });

  final LudoBoardPaths paths;
  final BoardCoordinateLayout layout;

  /// Returns null for yard and finished pawns because neither occupies a
  /// numbered track cell. Yard-slot and center-finish visuals are separate UI
  /// responsibilities.
  int? cellIdFor({
    required String playerId,
    required PawnRoutePosition position,
  }) {
    switch (position.section) {
      case PawnRouteSection.yard:
      case PawnRouteSection.finished:
        return null;
      case PawnRouteSection.mainTrack:
      case PawnRouteSection.homeLane:
        final progress = position.progress;
        if (progress == null || progress < 0) {
          throw ArgumentError(
            'A ${position.section.name} pawn requires non-negative progress.',
          );
        }
        final path = paths.forPlayer(playerId);
        if (position.section == PawnRouteSection.mainTrack &&
            progress >= path.trackLength) {
          throw ArgumentError(
            'Main-track progress $progress is outside the shared track.',
          );
        }
        if (position.section == PawnRouteSection.homeLane &&
            progress < path.trackLength) {
          throw ArgumentError(
            'Home-lane progress $progress is still on the shared track.',
          );
        }
        final cellId = path.cellAtProgress(progress);
        if (cellId == null) {
          throw ArgumentError(
            'Progress $progress is outside the route for player $playerId.',
          );
        }
        if (!layout.pointsByCell.containsKey(cellId)) {
          throw StateError(
            'Renderer has no coordinate for logical cell $cellId.',
          );
        }
        return cellId;
    }
  }
}
