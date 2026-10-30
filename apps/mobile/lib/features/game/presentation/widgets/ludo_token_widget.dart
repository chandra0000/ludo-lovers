import 'package:flutter/material.dart';

/// A zero-based cell coordinate on the 15x15 logical board.
@immutable
class GridPos {
  const GridPos(this.col, this.row);

  final int col;
  final int row;

  bool get isInsideBoard => col >= 0 && col < 15 && row >= 0 && row < 15;
}

/// Renders a token at the center of a logical board cell.
///
/// [boardRect] and this widget's enclosing Stack must use the same coordinate
/// space. The board rectangle is the actual square board artwork area, not the
/// full device viewport. This avoids MediaQuery-based offsets and preserves
/// alignment on phones with different aspect ratios.
class LudoTokenWidget extends StatelessWidget {
  const LudoTokenWidget({
    super.key,
    required this.gridPosition,
    required this.tokenColor,
    required this.boardRect,
    this.tokenRadius = 14.0,
  });

  final GridPos gridPosition;
  final Color tokenColor;
  final Rect boardRect;
  final double tokenRadius;

  @override
  Widget build(BuildContext context) {
    if (!gridPosition.isInsideBoard) {
      throw ArgumentError.value(
        gridPosition,
        'gridPosition',
        'Must be inside the 15x15 board.',
      );
    }
    if (!boardRect.isFinite || boardRect.width <= 0 || boardRect.height <= 0) {
      throw ArgumentError.value(
        boardRect,
        'boardRect',
        'Must be a finite, non-empty rectangle.',
      );
    }
    if (!tokenRadius.isFinite || tokenRadius <= 0) {
      throw ArgumentError.value(
        tokenRadius,
        'tokenRadius',
        'Must be finite and positive.',
      );
    }

    const gridSize = 15.0;
    final cellWidth = boardRect.width / gridSize;
    final cellHeight = boardRect.height / gridSize;
    final center = Offset(
      boardRect.left + (gridPosition.col + 0.5) * cellWidth,
      boardRect.top + (gridPosition.row + 0.5) * cellHeight,
    );

    // Keep the token within its cell on compact devices. Use the smaller cell
    // dimension so non-square layout constraints cannot stretch or clip it.
    final maxRadius = (cellWidth < cellHeight ? cellWidth : cellHeight) * 0.42;
    final radius = tokenRadius < maxRadius ? tokenRadius : maxRadius;

    return Positioned(
      left: center.dx - radius,
      top: center.dy - radius,
      width: radius * 2,
      height: radius * 2,
      child: Semantics(
        label: 'Ludo token',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokenColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.0),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
