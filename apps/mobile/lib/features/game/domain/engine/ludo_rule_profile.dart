/// Immutable, versioned configuration for a Ludo rules variant.
///
/// The current defaults describe a provisional local-MVP variant, not a
/// finalized or tournament-certified ruleset. Safe-cell indexes are global
/// shared-track indexes and must match the selected board definition.
library;

final class LudoRuleProfile {
  LudoRuleProfile({
    this.id = 'classic-v1-provisional',
    this.version = 1,
    Set<int> safeCellIndexes = const <int>{},
    this.sixRequiredToEnter = true,
    this.extraRollOnSix = true,
    this.extraRollOnCapture = true,
    this.extraRollOnFinish = true,
    this.requireExactFinishRoll = true,
    this.maxConsecutiveSixes = 3,
    this.thirdSixEndsTurnWithoutMove = true,
    this.finishEndsMatchImmediately = true,
    this.captureOnlySingleOpponentPawn = true,
  }) : safeCellIndexes = Set<int>.unmodifiable(safeCellIndexes) {
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
    if (this.safeCellIndexes.any((index) => index < 0)) {
      throw ArgumentError('Safe-cell indexes cannot be negative.');
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
}
