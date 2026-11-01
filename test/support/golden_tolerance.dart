import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.maxDiffRate = 0.08});

  final double maxDiffRate;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final List<int> goldenBytes = await getGoldenBytes(golden);
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      goldenBytes,
    );
    if (!result.passed && result.diffPercent > maxDiffRate) {
      final String error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return true;
  }
}

Future<void> expectGoldenWithinTolerance(
  WidgetTester tester,
  Finder finder, {
  required String goldenFile,
  required double maxDiffRate,
}) async {
  final previousComparator = goldenFileComparator;
  if (previousComparator is LocalFileComparator) {
    goldenFileComparator = TolerantGoldenComparator(
      previousComparator.basedir.resolve('test.dart'),
      maxDiffRate: maxDiffRate,
    );
  }
  try {
    await expectLater(finder, matchesGoldenFile(goldenFile));
  } finally {
    goldenFileComparator = previousComparator;
  }
}
