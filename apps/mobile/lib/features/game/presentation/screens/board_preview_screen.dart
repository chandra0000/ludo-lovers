import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

import '../../domain/board/board_coordinate_layout.dart';
import '../../domain/board/classic_ludo_board_coordinate_factory.dart';
import '../../domain/board/classic_ludo_board_definition.dart';
import '../../domain/board/classic_ludo_board_painter.dart';
import '../../domain/board/classic_ludo_pawn_layer.dart';

class BoardPreviewScreen extends StatefulWidget {
  const BoardPreviewScreen({super.key});

  @override
  State<BoardPreviewScreen> createState() => _BoardPreviewScreenState();
}

class _BoardPreviewScreenState extends State<BoardPreviewScreen> {
  late final BoardCoordinateLayout _layout =
      ClassicLudoBoardCoordinateFactory.create();
  int? _selectedCell;

  static const double _touchRadiusInCells = 0.48;

  List<BoardPawnMarker> get _previewPawns {
    const seats = ClassicLudoBoardDefinition.seats;
    return <BoardPawnMarker>[
      BoardPawnMarker(
        pawnId: 'preview-orange',
        cellId: seats[0].provisionalTrackEntryIndex,
        color: LudoBoardPalette.orange,
        selected: _selectedCell == seats[0].provisionalTrackEntryIndex,
      ),
      BoardPawnMarker(
        pawnId: 'preview-green',
        cellId: seats[1].provisionalTrackEntryIndex,
        color: LudoBoardPalette.green,
        selected: _selectedCell == seats[1].provisionalTrackEntryIndex,
      ),
      BoardPawnMarker(
        pawnId: 'preview-blue',
        cellId: seats[2].provisionalTrackEntryIndex,
        color: LudoBoardPalette.blue,
        selected: _selectedCell == seats[2].provisionalTrackEntryIndex,
      ),
      BoardPawnMarker(
        pawnId: 'preview-magenta',
        cellId: seats[3].provisionalTrackEntryIndex,
        color: LudoBoardPalette.magenta,
        selected: _selectedCell == seats[3].provisionalTrackEntryIndex,
      ),
    ];
  }

  void _handleBoardTap(TapDownDetails details, Size boardSize) {
    final cellSize = boardSize.shortestSide /
        ClassicLudoBoardDefinition.gridSize;
    final cellId = _layout.hitTest(
      x: details.localPosition.dx,
      y: details.localPosition.dy,
      width: boardSize.width,
      height: boardSize.height,
      maxDistance: cellSize * _touchRadiusInCells,
    );
    final selectableCells = _previewPawns.map((pawn) => pawn.cellId).toSet();
    setState(() {
      _selectedCell =
          cellId != null && selectableCells.contains(cellId) ? cellId : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classic Board'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: <Widget>[
              const Text(
                'A first look at the Ludo Lovers board',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCell == null
                    ? 'Tap a sample pawn to preview its selection highlight.'
                    : 'Sample pawn selected on cell $_selectedCell.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.cream,
                  height: 1.4,
                ),
              ),
              if (_selectedCell != null) ...<Widget>[
                const SizedBox(height: 2),
                TextButton.icon(
                  key: const ValueKey('clear_pawn_selection_button'),
                  onPressed: () => setState(() => _selectedCell = null),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear selection'),
                ),
              ],
              const SizedBox(height: 4),
              const Text(
                'Preview only: legal moves, turns and online play are not connected. Board route is provisional.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    key: const ValueKey('interactive_board'),
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.panel,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x55000000),
                            blurRadius: 22,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final boardSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (details) =>
                                  _handleBoardTap(details, boardSize),
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  const CustomPaint(
                                    painter: ClassicLudoBoardPainter(),
                                  ),
                                  IgnorePointer(
                                    child: CustomPaint(
                                      painter: ClassicLudoPawnLayer(
                                        layout: _layout,
                                        pawns: _previewPawns,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  _LegendDot(color: LudoBoardPalette.orange, label: 'Orange'),
                  _LegendDot(color: LudoBoardPalette.green, label: 'Green'),
                  _LegendDot(color: LudoBoardPalette.blue, label: 'Blue'),
                  _LegendDot(color: LudoBoardPalette.magenta, label: 'Magenta'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
