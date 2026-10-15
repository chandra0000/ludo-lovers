import 'package:flutter/material.dart';

import '../../domain/board/classic_ludo_board_painter.dart';
import '../../domain/board/classic_ludo_board_coordinate_factory.dart';
import '../../domain/board/classic_ludo_board_definition.dart';
import '../../domain/board/classic_ludo_pawn_layer.dart';

class BoardPreviewScreen extends StatelessWidget {
  const BoardPreviewScreen({super.key});

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
              const Text(
                'Board rendering preview — turns, pawn movement and online play are not connected yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFFFF8E1), height: 1.4),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF17191B),
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
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            const CustomPaint(
                              painter: ClassicLudoBoardPainter(),
                            ),
                            IgnorePointer(
                              child: CustomPaint(
                                painter: ClassicLudoPawnLayer(
                                  layout: ClassicLudoBoardCoordinateFactory.create(),
                                  pawns: <BoardPawnMarker>[
                                    BoardPawnMarker(
                                      pawnId: 'preview-orange',
                                      cellId: ClassicLudoBoardDefinition.seats[0].provisionalTrackEntryIndex,
                                      color: LudoBoardPalette.orange,
                                    ),
                                    BoardPawnMarker(
                                      pawnId: 'preview-green',
                                      cellId: ClassicLudoBoardDefinition.seats[1].provisionalTrackEntryIndex,
                                      color: LudoBoardPalette.green,
                                    ),
                                    BoardPawnMarker(
                                      pawnId: 'preview-blue',
                                      cellId: ClassicLudoBoardDefinition.seats[2].provisionalTrackEntryIndex,
                                      color: LudoBoardPalette.blue,
                                    ),
                                    BoardPawnMarker(
                                      pawnId: 'preview-magenta',
                                      cellId: ClassicLudoBoardDefinition.seats[3].provisionalTrackEntryIndex,
                                      color: LudoBoardPalette.magenta,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                  _LegendDot(color: Color(0xFFFF8928), label: 'Orange'),
                  _LegendDot(color: Color(0xFF33FF28), label: 'Green'),
                  _LegendDot(color: Color(0xFF289EFF), label: 'Blue'),
                  _LegendDot(color: Color(0xFFF428FF), label: 'Magenta'),
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
