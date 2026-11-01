import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled gameplay board artwork loads and decodes within the phone budget',
      () async {
    final data = await rootBundle.load('assets/images/ludo_board_glass.webp');
    expect(data.lengthInBytes, lessThan(300 * 1024));

    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      targetWidth: 576,
      targetHeight: 1024,
    );
    addTearDown(codec.dispose);

    final frame = await codec.getNextFrame();
    addTearDown(frame.image.dispose);

    expect(frame.image.width, lessThanOrEqualTo(576));
    expect(frame.image.height, lessThanOrEqualTo(1024));
    expect(frame.image.width, greaterThan(0));
    expect(frame.image.height, greaterThan(0));
  });
}
