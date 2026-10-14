import 'classic_ludo_board_coordinate_factory.dart';
import 'classic_ludo_board_definition.dart';

/// Structural audit for the provisional classic-board fixture.
///
/// A clean audit means the fixture is internally consistent; it does NOT mean
/// its visual route or rules have been approved against the brand reference.
class ClassicLudoBoardGeometryAudit {
  const ClassicLudoBoardGeometryAudit._();

  static List<String> inspect() {
    final issues = <String>[];
    const track = ClassicLudoBoardCoordinateFactory.sharedTrack;

    if (track.length != ClassicLudoBoardDefinition.sharedTrackLength) {
      issues.add('Shared track must contain exactly 52 cells.');
    }
    if (track.toSet().length != track.length) {
      issues.add('Shared track contains duplicate grid coordinates.');
    }
    for (var index = 0; index < track.length; index++) {
      if (!track[index].isInsideBoard) {
        issues.add('Track cell at index $index is outside the 15x15 grid.');
      }
    }

    final trackCells = track.toSet();
    for (var index = 0; index < track.length; index++) {
      final current = track[index];
      final next = track[(index + 1) % track.length];
      final dx = (current.column - next.column).abs();
      final dy = (current.row - next.row).abs();
      if (dx > 1 || dy > 1 || dx + dy == 0) {
        issues.add('Track transition $index to ${(index + 1) % track.length} is disconnected.');
      }
    }
    final laneCells = <BoardGridCell>{};
    final laneIds = <int>{};
    final entryIndexes = <int>{};

    for (final seat in ClassicLudoBoardDefinition.seats) {
      if (seat.provisionalTrackEntryIndex < 0 ||
          seat.provisionalTrackEntryIndex >= track.length) {
        issues.add('${seat.id} has an invalid provisional entry index.');
      } else {
        if (!entryIndexes.add(seat.provisionalTrackEntryIndex)) {
          issues.add('Two seats share a provisional track entry index.');
        }
        if (seat.startMarker !=
            track[seat.provisionalTrackEntryIndex]) {
          issues.add('${seat.id} start marker does not match its route index.');
        }
      }

      if (seat.homeLaneCells.length !=
          ClassicLudoBoardDefinition.homeLaneLength) {
        issues.add('${seat.id} must have six home-lane cells.');
      }
      if (seat.homeLaneCells.toSet().length != seat.homeLaneCells.length) {
        issues.add('${seat.id} has duplicate home-lane coordinates.');
      }
      if (seat.homeLaneCells.isNotEmpty) {
        if (seat.homeLaneCells.first != seat.laneStart) {
          issues.add('${seat.id} laneStart does not match the first home-lane cell.');
        }
        if (seat.homeLaneCells.last != seat.laneEnd) {
          issues.add('${seat.id} laneEnd does not match the last home-lane cell.');
        }
      }
      for (var index = 0; index + 1 < seat.homeLaneCells.length; index++) {
        final current = seat.homeLaneCells[index];
        final next = seat.homeLaneCells[index + 1];
        final distance = (current.column - next.column).abs() +
            (current.row - next.row).abs();
        if (distance != 1) {
          issues.add('${seat.id} home-lane cells are not orthogonally consecutive at index $index.');
        }
      }

      for (var index = 0; index < seat.homeLaneCells.length; index++) {
        final cell = seat.homeLaneCells[index];
        if (!cell.isInsideBoard) {
          issues.add('${seat.id} home-lane cell $index is outside the grid.');
        }
        if (trackCells.contains(cell)) {
          issues.add('${seat.id} home lane overlaps the shared track.');
        }
        if (!laneCells.add(cell)) {
          issues.add('Home lanes overlap at column ${cell.column}, row ${cell.row}.');
        }
      }

      for (final id in seat.homeLaneCellIds) {
        if (!laneIds.add(id)) {
          issues.add('Duplicate logical home-lane ID $id.');
        }
      }
    }

    if (laneIds.length !=
        ClassicLudoBoardDefinition.seats.length *
            ClassicLudoBoardDefinition.homeLaneLength) {
      issues.add('Expected 24 unique logical home-lane IDs.');
    }

    for (final safeId
        in ClassicLudoBoardDefinition.provisionalSafeTrackCellIds) {
      if (safeId < 0 || safeId >= track.length) {
        issues.add('Provisional safe cell $safeId is outside the shared track.');
      }
    }

    return List<String>.unmodifiable(issues);
  }

  /// True only for internal consistency, not final visual/rules approval.
  static bool get isStructurallyConsistent => inspect().isEmpty;
}
