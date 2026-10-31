/// Creates a fresh local game state for Classic or 2-vs-2 Team Up mode.
///
/// This factory initializes domain state only. It does not make the provisional
/// board route production-ready; use it for deterministic engine integration
/// and tests until the board topology has been approved.
library;

import '../board/classic_ludo_board_definition.dart';
import '../board/classic_ludo_board_fixture.dart';
import '../board/ludo_board_paths.dart';
import 'ludo_path_movement.dart';
import 'team_up_rules.dart';
import 'ludo_rule_profile.dart';
import 'path_based_local_game_engine.dart';

enum LocalGameMode { classic, teamUp }

class LocalGameSetup {
  const LocalGameSetup({
    required this.paths,
    required this.engine,
    required this.initialState,
    required this.mode,
  });

  final LudoBoardPaths paths;
  final PathBasedLocalGameEngine engine;
  final LocalGameState initialState;
  final LocalGameMode mode;
}

class LocalGameFactory {
  const LocalGameFactory._();

  static const List<String> playerIds = <String>[
    'orange',
    'green',
    'magenta',
    'blue',
  ];

  static LocalGameSetup create({
    Set<int>? safeCellIndexes,
    bool allowProvisionalRoutes = false,
    List<String>? selectedPlayerIds,
    LocalGameMode mode = LocalGameMode.classic,
  }) {
    final players = List<String>.unmodifiable(selectedPlayerIds ?? playerIds);
    if (players.length < 2 || players.length > playerIds.length) {
      throw ArgumentError.value(
        players.length,
        'selectedPlayerIds',
        'Choose between two and four players.',
      );
    }
    if (players.toSet().length != players.length ||
        players.any((playerId) => !playerIds.contains(playerId))) {
      throw ArgumentError.value(
        players,
        'selectedPlayerIds',
        'Player colours must be unique supported colours.',
      );
    }
    if (mode == LocalGameMode.teamUp &&
        (players.length != 4 || players.join(',') != TeamUpRules.turnOrder.join(','))) {
      throw ArgumentError.value(
        players,
        'selectedPlayerIds',
        'Team Up requires Orange, Green, Magenta and Blue in scheduled order.',
      );
    }
    if (!allowProvisionalRoutes) {
      throw StateError(
        'Classic board routes are provisional. Explicitly opt in only for '
        'development and tests; do not ship gameplay until topology is approved.',
      );
    }

    final paths = ClassicLudoBoardFixture.create();
    final engine = PathBasedLocalGameEngine(
      paths: paths,
      profile: LudoRuleProfile(
        id: mode == LocalGameMode.teamUp
            ? 'team-up-v1-provisional'
            : 'classic-v1-provisional',
        safeCellIndexes: safeCellIndexes ??
            ClassicLudoBoardDefinition.provisionalSafeTrackCellIds,
        isTeamUp: mode == LocalGameMode.teamUp,
      ),
    );
    final pawns = <LocalPawn>[
      for (final playerId in players)
        for (var index = 0; index < 4; index++)
          LocalPawn(
            id: '${playerId}_pawn_${index + 1}',
            playerId: playerId,
            position: const PawnRoutePosition(section: PawnRouteSection.yard),
          ),
    ];

    return LocalGameSetup(
      paths: paths,
      engine: engine,
      initialState: LocalGameState(
        players: players,
        pawns: pawns,
        currentPlayerIndex: 0,
        scheduledPlayerIndex: 0,
      ),
      mode: mode,
    );
  }
}
