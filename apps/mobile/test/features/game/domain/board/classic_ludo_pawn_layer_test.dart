import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/board_coordinate_layout.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_pawn_layer.dart';

void main() {
  testWidgets('renders pawns at logical cells and supports stacked occupants',
      (tester) async {
    final layout = ClassicLudoBoardCoordinateFactory.create();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            size: const Size(300, 300),
            painter: ClassicLudoPawnLayer(
              layout: layout,
              pawns: const <BoardPawnMarker>[
                BoardPawnMarker(
                  pawnId: 'orange-1',
                  cellId: 0,
                  color: LudoBoardPalette.orange,
                ),
                BoardPawnMarker(
                  pawnId: 'green-1',
                  cellId: 0,
                  color: LudoBoardPalette.green,
                  selected: true,
                ),
                BoardPawnMarker(
                  pawnId: 'blue-1',
                  cellId: 13,
                  color: LudoBoardPalette.blue,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('rejects duplicate pawn IDs and missing coordinate cells', () {
    final layout = ClassicLudoBoardCoordinateFactory.create();
    expect(
      () => ClassicLudoPawnLayer(
        layout: layout,
        pawns: const <BoardPawnMarker>[
          BoardPawnMarker(
            pawnId: 'duplicate',
            cellId: 0,
            color: LudoBoardPalette.orange,
          ),
          BoardPawnMarker(
            pawnId: 'duplicate',
            cellId: 1,
            color: LudoBoardPalette.green,
          ),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => ClassicLudoPawnLayer(
        layout: layout,
        pawns: const <BoardPawnMarker>[
          BoardPawnMarker(
            pawnId: 'missing-cell',
            cellId: 999,
            color: LudoBoardPalette.orange,
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}
