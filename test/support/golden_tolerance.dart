import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> expectGoldenWithinTolerance(
  WidgetTester tester,
  Finder finder, {
  required String goldenFile,
  required double maxDiffRate,
}) async {
  final comparator = goldenFileComparator;
  if (comparator is! LocalFileComparator) {
    await expectLater(finder, matchesGoldenFile(goldenFile));
    return;
  }

  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(finder);
  final image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      fail('Unable to capture PNG bytes for golden comparison: $goldenFile');
    }
    final imageBytes = byteData.buffer.asUint8List();
    final goldenBytes = await comparator.getGoldenBytes(Uri.parse(goldenFile));
    final comparison = await GoldenFileComparator.compareLists(
      imageBytes,
      goldenBytes,
    );

    expect(
      comparison.diffPercent,
      lessThanOrEqualTo(maxDiffRate),
      reason:
          'Golden "$goldenFile" diff ${comparison.diffPercent.toStringAsFixed(4)} '
          'exceeds allowed tolerance of $maxDiffRate',
    );
  } finally {
    image.dispose();
  }
}
