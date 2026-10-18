import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

import '../../domain/board/board_coordinate_layout.dart';
import '../../domain/board/classic_ludo_board_coordinate_factory.dart';
import '../../domain/board/classic_ludo_board_definition.dart';
import '../../domain/board/classic_ludo_board_geometry_audit.dart';
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


  void _showRouteAudit() {
    final auditIssues = ClassicLudoBoardGeometryAudit.inspect();
    final blockers = auditIssues
        .where((issue) => issue.contains('not an approved neighbouring-cell connection'))
        .toList(growable: false);
    final safeCells = ClassicLudoBoardDefinition.provisionalSafeTrackCellIds
        .toList()
      ..sort();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Route & safe-cell audit'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'NOT APPROVED FOR RELEASE',
                key: ValueKey('route_audit_blocked_status'),
                style: TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ClassicLudoBoardCoordinateFactory.isGameplayReady
                    ? 'Structural checks pass. Visual and rules approval is still required before release.'
                    : 'Structural geometry checks pass. Visual topology and rules approval are still required before release.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Diagonal corner transitions',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              if (blockers.isNotEmpty)
                for (final issue in blockers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $issue'),
                  ),
              if (ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes.isEmpty)
                const Text('No diagonal corner transitions detected.')
              else
                for (final index
                    in ClassicLudoBoardCoordinateFactory.nonOrthogonalTransitionIndexes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${ClassicLudoBoardCoordinateFactory.describeTransition(index)}',
                    ),
                  ),
              if (auditIssues.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                const Text(
                  'All structural findings',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                for (final issue in auditIssues)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $issue'),
                  ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Provisional safe track IDs',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(safeCells.join(', ')),
              const SizedBox(height: 6),
              const Text(
                'Safe-cell coordinates (column,row)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                safeCells
                    .map(ClassicLudoBoardCoordinateFactory.describeTrackCell)
                    .join(' · '),
                key: const ValueKey('safe_cell_coordinate_audit'),
              ),
              const SizedBox(height: 8),
              const Text(
                'The selected provisional profile models eight safe cells: the four player starts and one star cell eight track steps after each start. Public rules references describe this common pattern, but variants differ and cannot prove this custom board’s exact cell mapping. The four diagonal route transitions still block gameplay. Approve a straight-on 15×15 board diagram before enabling release gameplay.',
                style: TextStyle(color: AppTheme.mutedText, height: 1.4),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classic Board'),
        actions: <Widget>[
          IconButton(
            key: const ValueKey('board_route_audit_button'),
            tooltip: 'Route and safe-cell audit',
            onPressed: _showRouteAudit,
            icon: const Icon(Icons.fact_check_outlined),
          ),
        ],
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
              const SizedBox(height: 12),
              Container(
                key: const ValueKey('board_route_gate_summary'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.gpp_maybe_outlined,
                      color: AppTheme.gold,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'GAMEPLAY LOCKED · ROUTE REVIEW REQUIRED',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.45,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ClassicLudoBoardCoordinateFactory.invalidTransitionIndexes.length} invalid transitions · ${ClassicLudoBoardDefinition.provisionalSafeTrackCellIds.length} provisional safe cells',
                            key: const ValueKey('board_route_gate_counts'),
                            style: const TextStyle(
                              color: AppTheme.cream,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Review route geometry',
                      onPressed: _showRouteAudit,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
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
