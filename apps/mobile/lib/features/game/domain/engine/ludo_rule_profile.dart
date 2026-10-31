/// Immutable, versioned configuration for a Ludo rules variant.
///
/// The current defaults describe a provisional local-MVP variant, not a
/// finalized or tournament-certified ruleset. Safe-cell indexes are global
/// shared-track indexes and must match the selected board definition.
library;

import '../board/classic_ludo_board_definition.dart';

final class LudoRuleProfile {
  LudoRuleProfile({
    this.id = 'classic-v1-provisional',
    this.version = 1,
    Set<int>? safeCellIndexes,
    this.sixRequiredToEnter = true,
    this.extraRollOnSix = true,
    this.extraRollOnCapture = true,
    this.extraRollOnFinish = true,
    this.requireExactFinishRoll = true,
    this.maxConsecutiveSixes = 3,
    this.thirdSixEndsTurnWithoutMove = true,
    this.finishEndsMatchImmediately = true,
    this.captureOnlySingleOpponentPawn = true,
    this.isTeamUp = false,
  }) : safeCellIndexes = Set<int>.unmodifiable(
          safeCellIndexes ??
              ClassicLudoBoardDefinition.provisionalSafeTrackCellIds,
        ) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must not be empty.');
    }
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'Must be at least 1.');
    }
    if (maxConsecutiveSixes < 1) {
      throw ArgumentError.value(
        maxConsecutiveSixes,
        'maxConsecutiveSixes',
        'Must be at least 1.',
      );
    }
    if (this.safeCellIndexes.any(
      (index) =>
          index < 0 ||
          index >= ClassicLudoBoardDefinition.sharedTrackLength,
    )) {
      throw ArgumentError(
        'Safe-cell indexes must be within the canonical shared track.',
      );
    }
  }

  final String id;
  final int version;
  final Set<int> safeCellIndexes;
  final bool sixRequiredToEnter;
  final bool extraRollOnSix;
  final bool extraRollOnCapture;
  final bool extraRollOnFinish;
  final bool requireExactFinishRoll;
  final int maxConsecutiveSixes;
  final bool thirdSixEndsTurnWithoutMove;
  final bool finishEndsMatchImmediately;
  final bool captureOnlySingleOpponentPawn;
  final bool isTeamUp;
}
