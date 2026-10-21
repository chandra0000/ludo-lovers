import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_coordinate_factory.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_definition.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_board_painter.dart';
import 'package:ludo_lovers/features/game/domain/board/classic_ludo_pawn_layer.dart';
import 'package:ludo_lovers/features/game/presentation/screens/board_preview_screen.dart';

void main() {
  testWidgets(
    'rendered board is square and preview pawns use canonical cell centres',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: BoardPreviewScreen()),
      );
      await tester.pumpAndSettle();

      final boardFinder = find.byKey(const ValueKey('interactive_board'));
      expect(boardFinder, findsOneWidget);
      final boardSize = tester.getSize(boardFinder);
      expect(boardSize.width, closeTo(boardSize.height, 0.01));

      final boardPainterFinder = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is ClassicLudoBoardPainter,
      );
      final pawnPainterFinder = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is ClassicLudoPawnLayer,
      );
      expect(boardPainterFinder, findsOneWidget);
      expect(pawnPainterFinder, findsOneWidget);

      final boardCanvasSize = tester.getSize(boardPainterFinder);
      final pawnCanvasSize = tester.getSize(pawnPainterFinder);
      expect(pawnCanvasSize.width, closeTo(boardCanvasSize.width, 0.01));
      expect(pawnCanvasSize.height, closeTo(boardCanvasSize.height, 0.01));

      final pawnPainter = tester
          .widget<CustomPaint>(pawnPainterFinder)
          .painter! as ClassicLudoPawnLayer;
      final layout = ClassicLudoBoardCoordinateFactory.create();
      expect(pawnPainter.pawns, hasLength(4));

      for (final pawn in pawnPainter.pawns) {
        final actual = layout.pixelForCell(
          cellId: pawn.cellId,
          width: pawnCanvasSize.width,
          height: pawnCanvasSize.height,
        );
        final canonical = layout.forCell(pawn.cellId).toPixels(
          width: pawnCanvasSize.width,
          height: pawnCanvasSize.height,
        );
        expect(actual.x, closeTo(canonical.x, 0.01), reason: pawn.pawnId);
        expect(actual.y, closeTo(canonical.y, 0.01), reason: pawn.pawnId);
      }

      // Every shared-track cell must resolve to the centre of its 15x15 grid
      // square in the same canvas coordinate system used by the painter.
      for (var cellId = 0;
          cellId < ClassicLudoBoardDefinition.sharedTrackLength;
          cellId++) {
        final point = layout.forCell(cellId).toPixels(
          width: pawnCanvasSize.width,
          height: pawnCanvasSize.height,
        );
        final column = ClassicLudoBoardCoordinateFactory.sharedTrack[cellId].column;
        final row = ClassicLudoBoardCoordinateFactory.sharedTrack[cellId].row;
        final cellWidth = pawnCanvasSize.width /
            ClassicLudoBoardDefinition.gridSize;
        final cellHeight = pawnCanvasSize.height /
            ClassicLudoBoardDefinition.gridSize;
        expect(
          point.x,
          closeTo((column + 0.5) * cellWidth, 0.01),
          reason: 'track cell $cellId horizontal centre',
        );
        expect(
          point.y,
          closeTo((row + 0.5) * cellHeight, 0.01),
          reason: 'track cell $cellId vertical centre',
        );
      }

      expect(
        ClassicLudoBoardDefinition.isVisualTopologyApproved,
        isFalse,
        reason: 'render tests cannot substitute for on-device visual approval',
      );
      expect(ClassicLudoBoardCoordinateFactory.isGameplayReady, isFalse);
    },
  );
}
