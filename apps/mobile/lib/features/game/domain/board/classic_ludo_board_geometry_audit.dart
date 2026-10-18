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
    const finishCell = ClassicLudoBoardDefinition.centerFinishCell;
    if (!finishCell.isInsideBoard) {
      issues.add('Center finish cell is outside the 15x15 grid.');
    }
    if (trackCells.contains(finishCell)) {
      issues.add('Center finish cell overlaps the shared track.');
    }

    for (var index = 0; index < track.length; index++) {
      final current = track[index];
      final next = track[(index + 1) % track.length];
      final dx = (current.column - next.column).abs();
      final dy = (current.row - next.row).abs();
      final isOrthogonal = dx + dy == 1;
      final isExpectedDiagonal =
          const <int>{4, 17, 30, 43}.contains(index) && dx == 1 && dy == 1;
      if (!isOrthogonal && !isExpectedDiagonal) {
        issues.add(
          'Track transition $index to ${(index + 1) % track.length} '
          'is not an approved neighbouring-cell connection.',
        );
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
        issues.add('${seat.id} must have five home-lane cells.');
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

      if (seat.homeLaneCells.contains(finishCell)) {
        issues.add('${seat.id} home lane overlaps the center finish cell.');
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
      issues.add('Expected 20 unique logical home-lane IDs.');
    }

    for (final safeId
        in ClassicLudoBoardDefinition.provisionalSafeTrackCellIds) {
      if (safeId < 0 || safeId >= track.length) {
        issues.add('Provisional safe cell $safeId is outside the shared track.');
      }
    }

    // This prototype currently models the common eight-square profile:
    // four player starts plus one star square eight track cells after each
    // start. This is a rules-profile consistency check, not visual approval.
    final expectedSafeCells = <int>{};
    for (final seat in ClassicLudoBoardDefinition.seats) {
      final entry = seat.provisionalTrackEntryIndex;
      if (entry < 0 || entry >= track.length) continue;
      expectedSafeCells
        ..add(entry)
        ..add((entry + 8) % track.length);
      if (!ClassicLudoBoardDefinition.provisionalSafeTrackCellIds.contains(entry)) {
        issues.add(
          '${seat.id} start cell $entry is missing from provisional safe cells.',
        );
      }
    }
    const actualSafeCells =
        ClassicLudoBoardDefinition.provisionalSafeTrackCellIds;
    if (expectedSafeCells.length != actualSafeCells.length ||
        !expectedSafeCells.containsAll(actualSafeCells) ||
        !actualSafeCells.containsAll(expectedSafeCells)) {
      issues.add(
        'Provisional safe cells must match the selected profile: four starts '
        'plus the four track cells eight steps after each start.',
      );
    }

    if (ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes.isNotEmpty) {
      issues.add('Shared track contains invalid transitions outside the four documented diagonal corners.');
    }

    return List<String>.unmodifiable(issues);
  }

  /// True only for internal consistency, not final visual/rules approval.
  static bool get isStructurallyConsistent => inspect().isEmpty;
}
