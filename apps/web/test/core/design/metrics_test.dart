import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/design/tokens.dart';

void main() {
  test('fab clearance leaves room for an extended fab and its margin', () {
    // Extended fab: 48 px tall, 16 px margin to the edge, plus 24 px of air.
    expect(HoopsSize.fabClearance, 88);
    expect(
      HoopsSize.fabClearance,
      greaterThanOrEqualTo(HoopsSize.minTapTarget + HoopsSpace.md),
    );
  });
}
