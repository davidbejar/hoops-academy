// Runs before every test file in this package (flutter_test convention).
//
// Goldens are recorded on macOS and compared pixel-exact there. On the Linux CI runner the same frames differ by a few
// percent (anti-aliasing of the test font and of shapes), so CI sets GOLDEN_DIFF_TOLERANCE (fraction, e.g. 0.06) and
// this comparator accepts diffs up to that ratio; without the variable the comparison stays exact. Failing diffs are
// still written to test/golden/failures/ in both modes.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final raw = Platform.environment['GOLDEN_DIFF_TOLERANCE'];
  final tolerance = raw == null ? 0.0 : (double.tryParse(raw) ?? 0.0);
  if (tolerance > 0 && goldenFileComparator is LocalFileComparator) {
    // LocalFileComparator takes the *test file* URI and uses its directory, so hand it a file inside basedir.
    final base = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenComparator(
      base.basedir.resolve('golden_test.dart'),
      tolerance,
    );
  }
  await testMain();
}

class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.basedir, this.tolerance);

  /// Maximum accepted ratio of differing pixels (0.06 = 6 %).
  final double tolerance;

  @override
  Future<bool> compare(List<int> imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(
      '$error (tolerance ${(tolerance * 100).toStringAsFixed(1)} %)',
    );
  }
}
