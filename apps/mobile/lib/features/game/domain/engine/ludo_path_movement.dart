/// Path-based pawn movement helpers for Ludo Lovers.
///
/// These helpers are deliberately independent of Flutter/Flame. The game state
/// should store player-relative progress; the renderer maps returned logical
/// cells to board coordinates.
import '../board/ludo_board_paths.dart';

enum PawnRouteSection { yard, mainTrack, homeLane, finished }

class PawnRoutePosition {
  const PawnRoutePosition({
    required this.section,
    this.progress,
  });

  final PawnRouteSection section;

  /// Progress measured from the player's entry cell:
  /// 0..trackLength-1 = shared track, trackLength..finishProgress-1 = home lane,
  /// finishProgress = finished. Null means the pawn is still in its yard.
  final int? progress;
}

class PawnMoveResolution {
  const PawnMoveResolution({
    required this.position,
    required this.destinationCell,
    required this.finishes,
  });

  final PawnRoutePosition position;

  /// Null when the pawn finishes in the center rather than occupying a cell.
  final int? destinationCell;
  final bool finishes;
}

enum PawnMoveFailure { invalidDice, pawnInYardNeedsSix, alreadyFinished, overshoot }

class PawnMoveResult {
  const PawnMoveResult.success(this.resolution) : failure = null;
  const PawnMoveResult.failure(this.failure) : resolution = null;

  final PawnMoveResolution? resolution;
  final PawnMoveFailure? failure;
  bool get isSuccess => resolution != null;
}

/// Resolves a single pawn move against its own route. Captures, safe cells,
/// turn bonuses and player ownership are handled by the game engine separately.
class LudoPathMovement {
  const LudoPathMovement();

  PawnMoveResult resolve({
    required LudoPlayerPath path,
    required PawnRoutePosition current,
    required int diceValue,
    required bool sixRequiredToEnter,
    required bool requireExactFinishRoll,
  }) {
    if (diceValue < 1 || diceValue > 6) {
      return const PawnMoveResult.failure(PawnMoveFailure.invalidDice);
    }

    if (current.section == PawnRouteSection.finished) {
      return const PawnMoveResult.failure(PawnMoveFailure.alreadyFinished);
    }

    if (current.section == PawnRouteSection.yard) {
      if (sixRequiredToEnter && diceValue != 6) {
        return const PawnMoveResult.failure(PawnMoveFailure.pawnInYardNeedsSix);
      }
      return PawnMoveResult.success(
        PawnMoveResolution(
          position: const PawnRoutePosition(
            section: PawnRouteSection.mainTrack,
            progress: 0,
          ),
          destinationCell: path.entryCell,
          finishes: false,
        ),
      );
    }

    final progress = current.progress;
    if (progress == null || progress < 0 || progress > path.finishProgress) {
      return const PawnMoveResult.failure(PawnMoveFailure.overshoot);
    }

    final target = progress + diceValue;
    if (target > path.finishProgress) {
      if (requireExactFinishRoll) {
        return const PawnMoveResult.failure(PawnMoveFailure.overshoot);
      }
      return PawnMoveResult.success(
        PawnMoveResolution(
          position: PawnRoutePosition(
            section: PawnRouteSection.finished,
            progress: path.finishProgress,
          ),
          destinationCell: null,
          finishes: true,
        ),
      );
    }

    if (target == path.finishProgress) {
      return PawnMoveResult.success(
        PawnMoveResolution(
          position: PawnRoutePosition(
            section: PawnRouteSection.finished,
            progress: path.finishProgress,
          ),
          destinationCell: null,
          finishes: true,
        ),
      );
    }

    final destination = path.cellAtProgress(target);
    if (destination == null) {
      return const PawnMoveResult.failure(PawnMoveFailure.overshoot);
    }
    final section = target < path.trackLength
        ? PawnRouteSection.mainTrack
        : PawnRouteSection.homeLane;

    return PawnMoveResult.success(
      PawnMoveResolution(
        position: PawnRoutePosition(section: section, progress: target),
        destinationCell: destination,
        finishes: false,
      ),
    );
  }
}
