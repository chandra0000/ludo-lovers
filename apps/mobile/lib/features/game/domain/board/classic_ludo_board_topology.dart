import 'classic_ludo_board_definition.dart';

/// Audits the logical 15x15 board as an orthogonal grid graph.
///
/// A 52-cell route may be unique, in bounds, and visually plausible while
/// still violating orthogonal adjacency. This class keeps those concerns
/// separate and also checks the checkerboard-parity constraint imposed by
/// four entry markers separated by 13 route edges.
class ClassicLudoBoardTopology {
  const ClassicLudoBoardTopology._();

  static int _parity(BoardGridCell cell) =>
      (cell.column + cell.row).isEven ? 0 : 1;

  /// Indexes of shared-track edges that are not one-cell orthogonal moves.
  /// The index identifies the edge from [index] to [(index + 1) % 52].
  static List<int> get nonOrthogonalEdgeIndexes {
    final track = ClassicLudoBoardDefinition.sharedTrackCells;
    final result = <int>[];
    for (var index = 0; index < track.length; index++) {
      final from = track[index];
      final to = track[(index + 1) % track.length];
      final distance = (from.column - to.column).abs() +
          (from.row - to.row).abs();
      if (distance != 1) result.add(index);
    }
    return List<int>.unmodifiable(result);
  }

  /// Entry-marker parity conflicts with an orthogonal route of the required
  /// number of edges. Every orthogonal step flips checkerboard parity, so an
  /// odd number of steps must end on the opposite parity.
  ///
  /// Entries are compared in route order, including Blue -> Orange wrap.
  static List<String> get entryParityConflicts {
    final seats = ClassicLudoBoardDefinition.seats.toList()
      ..sort((a, b) =>
          a.provisionalTrackEntryIndex.compareTo(b.provisionalTrackEntryIndex));
    final conflicts = <String>[];
    if (seats.length < 2) return const <String>[];

    for (var index = 0; index < seats.length; index++) {
      final current = seats[index];
      final next = seats[(index + 1) % seats.length];
      final edgeCount = (next.provisionalTrackEntryIndex -
              current.provisionalTrackEntryIndex +
              ClassicLudoBoardDefinition.sharedTrackLength) %
          ClassicLudoBoardDefinition.sharedTrackLength;
      final from = ClassicLudoBoardDefinition.sharedTrackCells[
          current.provisionalTrackEntryIndex];
      final to = ClassicLudoBoardDefinition.sharedTrackCells[
          next.provisionalTrackEntryIndex];
      final parityMustFlip = edgeCount.isOdd;
      final parityActuallyFlips = _parity(from) != _parity(to);
      if (parityMustFlip != parityActuallyFlips) {
        conflicts.add(
          '${current.id}(${current.provisionalTrackEntryIndex}) -> '
          '${next.id}(${next.provisionalTrackEntryIndex}): '
          '$edgeCount orthogonal steps require '
          '${parityMustFlip ? 'opposite' : 'matching'} parity, but '
          '(${from.column},${from.row}) and (${to.column},${to.row}) '
          'have ${parityActuallyFlips ? 'opposite' : 'matching'} parity.',
        );
      }
    }
    return List<String>.unmodifiable(conflicts);
  }

  /// True only when all 52 edges, including 51 -> 0, are orthogonal.
  static bool get isOrthogonalCycle =>
      ClassicLudoBoardDefinition.sharedTrackLength == 52 &&
      nonOrthogonalEdgeIndexes.isEmpty;

  /// True when all seat-entry offsets can coexist with orthogonal movement.
  static bool get hasCompatibleEntryParity => entryParityConflicts.isEmpty;

  /// Structural orthogonal topology gate. Visual approval remains separate.
  static bool get isOrthogonalTopologyValid =>
      isOrthogonalCycle && hasCompatibleEntryParity;

  /// Human-readable blockers for the current board definition.
  static List<String> inspect() {
    final issues = <String>[];
    final track = ClassicLudoBoardDefinition.sharedTrackCells;
    if (track.length != ClassicLudoBoardDefinition.sharedTrackLength) {
      issues.add('Expected exactly 52 shared-track cells; found ${track.length}.');
    }
    if (track.toSet().length != track.length) {
      issues.add('Shared track contains duplicate grid coordinates.');
    }
    for (var index = 0; index < track.length; index++) {
      if (!track[index].isInsideBoard) {
        issues.add('Shared-track cell $index is outside the 15x15 grid.');
      }
    }
    for (final edgeIndex in nonOrthogonalEdgeIndexes) {
      final from = track[edgeIndex];
      final to = track[(edgeIndex + 1) % track.length];
      issues.add(
        'Shared-track edge $edgeIndex -> ${(edgeIndex + 1) % track.length} '
        'is not orthogonal: (${from.column},${from.row}) -> '
        '(${to.column},${to.row}).',
      );
    }
    issues.addAll(entryParityConflicts);
    return List<String>.unmodifiable(issues);
  }
}
