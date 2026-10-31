import 'board_coordinate_layout.dart';
import 'classic_ludo_board_definition.dart';
import 'classic_ludo_board_topology.dart';

/// Provisional 15x15 grid route used to unify rendering and hit-testing.
///
/// Coordinates use (column, row) with the origin at the top-left. The route
/// follows a conventional 52-cell loop; it is not yet approved against the
/// supplied visual reference and must not be treated as a final rules profile.
class ClassicLudoBoardCoordinateFactory {
  const ClassicLudoBoardCoordinateFactory._();

  /// Compatibility alias; the canonical physical route lives in the definition.
  static const List<BoardGridCell> sharedTrack =
      ClassicLudoBoardDefinition.sharedTrackCells;

  /// Explicit corner connectors in the current artwork-aligned candidate.
  ///
  /// These are intentional one-cell diagonal transitions in the reference
  /// geometry, not arbitrary jumps. They remain visible to the audit and do
  /// not constitute visual approval: [isGameplayReady] stays false until the
  /// board-cell mapping is signed off against the reference artwork.
  static const Set<int> referenceCornerConnectorIndexes = <int>{4, 17, 30, 43};

  /// Indexes whose next route cell is diagonal rather than orthogonally adjacent.
  static List<int> get nonOrthogonalTransitionIndexes {
    final indexes = <int>[];
    for (var index = 0; index < sharedTrack.length; index++) {
      final current = sharedTrack[index];
      final next = sharedTrack[(index + 1) % sharedTrack.length];
      final dx = (current.column - next.column).abs();
      final dy = (current.row - next.row).abs();
      if (dx + dy != 1) indexes.add(index);
    }
    return List<int>.unmodifiable(indexes);
  }

  /// Human-readable coordinates for reviewing a route transition in the audit UI.
  ///
  /// IDs are physical shared-track indexes. This reports geometry only; it
  /// does not decide whether a transition is valid under the approved rules.
  static String describeTransition(int index) {
    if (index < 0 || index >= sharedTrack.length) {
      throw RangeError.index(index, sharedTrack, 'index');
    }
    final nextIndex = (index + 1) % sharedTrack.length;
    final from = sharedTrack[index];
    final to = sharedTrack[nextIndex];
    return '$index (${from.column},${from.row}) → '
        '$nextIndex (${to.column},${to.row})';
  }

  /// Human-readable coordinate for a physical shared-track cell.
  static String describeTrackCell(int index) {
    if (index < 0 || index >= sharedTrack.length) {
      throw RangeError.index(index, sharedTrack, 'index');
    }
    final cell = sharedTrack[index];
    return '$index (${cell.column},${cell.row})';
  }

  /// Diagonal transitions not covered by the documented reference connectors.
  /// This detects accidental new jumps without misclassifying known corners.
  static List<int> get unmappedTransitionIndexes =>
      List<int>.unmodifiable(nonOrthogonalTransitionIndexes.where(
        (index) => !referenceCornerConnectorIndexes.contains(index),
      ));

  /// Non-orthogonal edges retained as a release-review signal for compatibility.
  /// This includes documented connectors; it is not the same as an unknown jump.
  static List<int> get invalidTransitionIndexes => nonOrthogonalTransitionIndexes;

  /// True only when the full loop and its seat-entry parity satisfy the
  /// orthogonal-grid contract. The current reference candidate does not.
  static bool get isOrthogonallyContinuous =>
      ClassicLudoBoardTopology.isOrthogonalTopologyValid;

  /// Detailed blockers for the requested orthogonal route contract.
  static List<String> get topologyBlockers =>
      ClassicLudoBoardTopology.inspect();

  /// Conservative release gate for consuming this geometry in game rules.
  ///
  /// Structural checks may pass while visual approval is still outstanding.
  /// Keep the explicit approval flag false until the actual board artwork and
  /// selected rules profile have been reviewed.
  static bool get isGameplayReady {
    if (sharedTrack.length != ClassicLudoBoardDefinition.sharedTrackLength ||
        sharedTrack.toSet().length != sharedTrack.length ||
        !sharedTrack.every((cell) => cell.isInsideBoard) ||
        unmappedTransitionIndexes.isNotEmpty ||
        !ClassicLudoBoardTopology.isOrthogonalTopologyValid ||
        !ClassicLudoBoardDefinition.isVisualTopologyApproved) {
      return false;
    }

    const safeCells = ClassicLudoBoardDefinition.provisionalSafeTrackCellIds;
    if (!safeCells.every((id) => id >= 0 && id < sharedTrack.length)) {
      return false;
    }

    // A player's entry cell must be the same physical cell as their marker,
    // and must be protected under the selected rules profile.
    for (final seat in ClassicLudoBoardDefinition.seats) {
      final entry = seat.provisionalTrackEntryIndex;
      if (entry < 0 ||
          entry >= sharedTrack.length ||
          seat.startMarker != sharedTrack[entry] ||
          !safeCells.contains(entry)) {
        return false;
      }
      final approach = sharedTrack[
        (entry + ClassicLudoBoardDefinition.playerTrackLength - 1) %
            sharedTrack.length
      ];
      final firstLane = seat.homeLaneCells.first;
      final dx = (approach.column - firstLane.column).abs();
      final dy = (approach.row - firstLane.row).abs();
      final distance = dx + dy;
      final connected = distance == 1 || (dx == 1 && dy == 1);
      if (!connected) return false;
    }

    // A track must not reuse a physical cell as part of a private home lane.
    final trackCells = sharedTrack.toSet();
    for (final seat in ClassicLudoBoardDefinition.seats) {
      if (seat.homeLaneCells.length !=
              ClassicLudoBoardDefinition.homeLaneLength ||
          seat.homeLaneCells.toSet().length != seat.homeLaneCells.length ||
          seat.homeLaneCells.any(
            (cell) => !cell.isInsideBoard || trackCells.contains(cell),
          )) {
        return false;
      }
    }

    return true;
  }

  static BoardCoordinateLayout create() {
    if (sharedTrack.length != ClassicLudoBoardDefinition.sharedTrackLength) {
      throw StateError('The shared route must contain exactly 52 cells.');
    }

    final points = <int, BoardPoint>{};
    for (var index = 0; index < sharedTrack.length; index++) {
      final cell = sharedTrack[index];
      if (!cell.isInsideBoard) {
        throw StateError('Track cell $index is outside the 15x15 board.');
      }
      points[index] = BoardPoint(
        x: (cell.column + 0.5) / ClassicLudoBoardDefinition.gridSize,
        y: (cell.row + 0.5) / ClassicLudoBoardDefinition.gridSize,
      );
    }

    for (final seat in ClassicLudoBoardDefinition.seats) {
      for (var index = 0; index < seat.homeLaneCells.length; index++) {
        final cell = seat.homeLaneCells[index];
        final cellId = seat.homeLaneStartCellId + index;
        points[cellId] = BoardPoint(
          x: (cell.column + 0.5) / ClassicLudoBoardDefinition.gridSize,
          y: (cell.row + 0.5) / ClassicLudoBoardDefinition.gridSize,
        );
      }
    }

    return BoardCoordinateLayout(points);
  }
}
