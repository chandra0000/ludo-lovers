import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Immutable measurements for the approved 576 × 1024 game artwork.
abstract final class LudoDimensions {
  static const Size canvas = Size(576, 1024);
  static const Rect board = Rect.fromLTRB(17, 205, 559, 747);
  static const double gridSize = 15;
  static const double cell = 542 / gridSize;
  static const double trackPawnDiameter = 32;
  static const double yardPawnDiameter = 38;
  static const double stackedPawnDiameter = 22;
  static const double minimumHitTarget = 44;
  static const Offset diceCenter = Offset(288, 840);
  static const Offset chatCenter = Offset(98, 940);
  static const Offset reactionCenter = Offset(478, 940);
  static const Offset helpCenter = Offset(520, 50);
  static const Rect turnBanner = Rect.fromLTRB(200, 924, 376, 956);

  static double scaleFor(Size viewport) =>
      math.min(viewport.width / canvas.width, viewport.height / canvas.height);

  static Rect project(Rect source, Offset origin, double scale) => Rect.fromLTWH(
        origin.dx + source.left * scale,
        origin.dy + source.top * scale,
        source.width * scale,
        source.height * scale,
      );

  static Offset projectPoint(Offset point, Offset origin, double scale) =>
      origin + point * scale;
}
