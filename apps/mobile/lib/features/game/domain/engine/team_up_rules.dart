/// Team Up rules shared by local gameplay and future authoritative sessions.
library;

enum TeamUpTeam { a, b }

enum TeamUpCellOutcome { friendlyStack, opposingStack, safeCell }

/// Product rules for the 2-vs-2 mode. The seat order is always
/// Orange -> Green -> Magenta -> Blue.
final class TeamUpRules {
  const TeamUpRules._();

  static const List<String> turnOrder = <String>[
    'orange',
    'green',
    'magenta',
    'blue',
  ];

  static const Map<String, TeamUpTeam> _teams = <String, TeamUpTeam>{
    'orange': TeamUpTeam.a,
    'magenta': TeamUpTeam.a,
    'green': TeamUpTeam.b,
    'blue': TeamUpTeam.b,
  };

  static TeamUpTeam teamFor(String playerId) {
    final team = _teams[playerId];
    if (team == null) {
      throw ArgumentError.value(playerId, 'playerId', 'Unknown Team Up player.');
    }
    return team;
  }

  static String teammateFor(String playerId) {
    teamFor(playerId);
    return switch (playerId) {
      'orange' => 'magenta',
      'magenta' => 'orange',
      'green' => 'blue',
      'blue' => 'green',
      _ => throw ArgumentError.value(playerId, 'playerId'),
    };
  }

  /// The scheduled player still rolls. If all their pawns are finished, the
  /// roll is assigned to their teammate; if both are finished, the turn is
  /// skipped. The caller must preserve the scheduled seat separately from the
  /// recipient so the displayed turn order never changes.
  static String? recipientForScheduledRoll({
    required String scheduledPlayerId,
    required Set<String> playersWithAllPawnsFinished,
  }) {
    teamFor(scheduledPlayerId);
    if (!playersWithAllPawnsFinished.contains(scheduledPlayerId)) {
      return scheduledPlayerId;
    }
    final teammate = teammateFor(scheduledPlayerId);
    return playersWithAllPawnsFinished.contains(teammate) ? null : teammate;
  }

  /// A bonus roll belongs to the same recipient as the roll that earned it.
  /// Call this for each additional roll; do not advance the scheduled seat.
  static String? recipientForBonusRoll({
    required String rollRecipientPlayerId,
    required Set<String> playersWithAllPawnsFinished,
  }) =>
      recipientForScheduledRoll(
        scheduledPlayerId: rollRecipientPlayerId,
        playersWithAllPawnsFinished: playersWithAllPawnsFinished,
      );

  static bool hasTeamWon({
    required TeamUpTeam team,
    required Set<String> playersWithAllPawnsFinished,
  }) {
    final members = _teams.entries
        .where((entry) => entry.value == team)
        .map((entry) => entry.key);
    return members.every(playersWithAllPawnsFinished.contains);
  }

  /// Safe cells protect everyone. Else, teammates share a friendly stack;
  /// opposing teams use the configured local opponent-stack capture policy.
  static TeamUpCellOutcome classifyCell({
    required String arrivingPlayerId,
    required String occupyingPlayerId,
    required bool isSafeCell,
  }) {
    teamFor(arrivingPlayerId);
    teamFor(occupyingPlayerId);
    if (isSafeCell) return TeamUpCellOutcome.safeCell;
    return teamFor(arrivingPlayerId) == teamFor(occupyingPlayerId)
        ? TeamUpCellOutcome.friendlyStack
        : TeamUpCellOutcome.opposingStack;
  }
}
