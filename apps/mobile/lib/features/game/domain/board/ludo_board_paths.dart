/// Ludo Lovers board-path model (Step 07).
///
/// Geometry is logical, not pixel-based. Supply each player's ordered route as
/// global main-track cell indexes starting at that player's entry cell, then
/// the private home-lane cells in order. The final home destination is separate.
///
/// IMPORTANT: Populate the routes from the approved board design and verify
/// them against a diagram before connecting this model to movement rules.
class LudoPlayerPath {
  LudoPlayerPath({
    required this.playerId,
    required List<int> mainTrackCells,
    required List<int> homeLaneCells,
    required this.trackLength,
  })  : mainTrackCells = List<int>.unmodifiable(mainTrackCells),
        homeLaneCells = List<int>.unmodifiable(homeLaneCells) {
    if (playerId.isEmpty) {
      throw ArgumentError.value(playerId, 'playerId', 'Must not be empty.');
    }
    if (trackLength <= 0) {
      throw ArgumentError.value(trackLength, 'trackLength', 'Must be positive.');
    }
    // Keep all physical shared cells for board/capture validation. Movement
    // traverses only trackLength cells before turning into the home lane.
    if (this.mainTrackCells.length < trackLength ||
        this.mainTrackCells.length > trackLength + 1) {
      throw ArgumentError(
        'Player $playerId must provide the traversed route and at most one '
        'additional physical shared-track cell.',
      );
    }
    if (this.mainTrackCells.toSet().length != this.mainTrackCells.length) {
      throw ArgumentError('Main-track route for $playerId contains duplicates.');
    }
    if (this.mainTrackCells.any(
      (cell) => cell < 0 || cell >= this.mainTrackCells.length,
    )) {
      throw ArgumentError('Main-track route for $playerId contains invalid physical cell IDs.');
    }
    if (this.homeLaneCells.any((cell) => cell < 0)) {
      throw ArgumentError('Home-lane cell indexes must be non-negative.');
    }
    if (this.homeLaneCells.toSet().length != this.homeLaneCells.length) {
      throw ArgumentError('Home-lane route for $playerId contains duplicates.');
    }
  }

  final String playerId;
  final List<int> mainTrackCells;
  final List<int> homeLaneCells;
  final int trackLength;

  int get entryCell => mainTrackCells.first;
  int get homeLaneLength => homeLaneCells.length;

  /// Returns a global board cell for a player-relative distance from entry.
  /// Distances 0..trackLength-1 traverse the shared loop up to the home-lane
  /// branch; subsequent distances address the private lane. An extra physical
  /// loop cell may remain in [mainTrackCells] for shared-cell validation but
  /// is not traversed by this player. The center finish is not a track cell.
  int? cellAtProgress(int progress) {
    if (progress < 0) {
      throw ArgumentError.value(progress, 'progress', 'Must not be negative.');
    }
    if (progress < mainTrackCells.length) {
      return mainTrackCells[progress];
    }
    final homeIndex = progress - mainTrackCells.length;
    if (homeIndex < homeLaneCells.length) {
      return homeLaneCells[homeIndex];
    }
    return null;
  }

  /// A legal move must land on a represented path cell or exactly on the
  /// final-home position (progress == route length). Values beyond it overshoot.
  bool canAdvance({
    required int currentProgress,
    required int diceValue,
    required bool requireExactFinish,
  }) {
    if (currentProgress < 0 || diceValue < 1 || diceValue > 6) return false;
    final finishProgress = mainTrackCells.length + homeLaneCells.length;
    final target = currentProgress + diceValue;
    if (target > finishProgress) return !requireExactFinish;
    return true;
  }

  int get finishProgress => mainTrackCells.length + homeLaneCells.length;
}

/// Holds the independently defined route for each player. It does not invent
/// geometry: callers must provide routes taken from the final board layout.
class LudoBoardPaths {
  LudoBoardPaths(Iterable<LudoPlayerPath> paths)
      : pathsByPlayer = _indexPaths(paths) {
    if (pathsByPlayer.length < 2 || pathsByPlayer.length > 4) {
      throw ArgumentError('Board must define paths for 2 to 4 players.');
    }

    final routes = pathsByPlayer.values.toList(growable: false);
    final reference = routes.first;
    final sharedCells = reference.mainTrackCells.toSet();
    final homeCells = <int>{};

    for (final route in routes) {
      if (route.trackLength != reference.trackLength ||
          route.mainTrackCells.toSet().length != sharedCells.length ||
          !route.mainTrackCells.toSet().containsAll(sharedCells)) {
        throw ArgumentError(
          'Every player route must describe the same shared-track cells.',
        );
      }
      if (route.homeLaneLength != reference.homeLaneLength) {
        throw ArgumentError('Every player route must have the same home-lane length.');
      }
      if (route.homeLaneCells.any(sharedCells.contains)) {
        throw ArgumentError('Home-lane cells must not overlap the shared track.');
      }
      for (final cell in route.homeLaneCells) {
        if (!homeCells.add(cell)) {
          throw ArgumentError('Home-lane cells must be unique across players.');
        }
      }
    }
  }

  static Map<String, LudoPlayerPath> _indexPaths(
    Iterable<LudoPlayerPath> paths,
  ) {
    final indexed = <String, LudoPlayerPath>{};
    for (final path in paths) {
      if (indexed.containsKey(path.playerId)) {
        throw ArgumentError('Duplicate route for player ${path.playerId}.');
      }
      indexed[path.playerId] = path;
    }
    return Map<String, LudoPlayerPath>.unmodifiable(indexed);
  }

  final Map<String, LudoPlayerPath> pathsByPlayer;

  LudoPlayerPath forPlayer(String playerId) {
    final path = pathsByPlayer[playerId];
    if (path == null) {
      throw ArgumentError('No board path defined for player $playerId.');
    }
    return path;
  }
}
