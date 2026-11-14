import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/list_row.dart';

import '../../support/kit_harness.dart';

void main() {
  test('initials: two words, one word, empty', () {
    expect(InitialsAvatar.initials('Ana Ruiz'), 'AR');
    expect(InitialsAvatar.initials('  leo   gil  marín'), 'LG');
    expect(InitialsAvatar.initials('Mini'), 'MI');
    expect(InitialsAvatar.initials('A'), 'A');
    expect(InitialsAvatar.initials('   '), '?');
  });

  testWidgets('title, subtitle, avatar and trailing', (tester) async {
    await pumpKit(
      tester,
      const ListRow(
        title: 'Ana Ruiz',
        subtitle: 'Mini A · #7',
        leading: InitialsAvatar(name: 'Ana Ruiz'),
        trailing: Text('12 PTS'),
      ),
    );
    expect(find.text('Ana Ruiz'), findsOneWidget);
    expect(find.text('Mini A · #7'), findsOneWidget);
    expect(find.text('AR'), findsOneWidget);
    expect(find.text('12 PTS'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('tappable rows show a chevron and call onTap', (tester) async {
    var taps = 0;
    await pumpKit(
      tester,
      ListRow(key: const Key('row'), title: 'Mini A', onTap: () => taps++),
    );
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    await tester.tap(find.byKey(const Key('row')));
    expect(taps, 1);
    expect(
      tester.getSize(find.byKey(const Key('row'))).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('details sit under the subtitle, inside the row', (tester) async {
    await pumpKit(
      tester,
      const ListRow(
        key: Key('row'),
        title: 'Ana Ruiz',
        subtitle: 'Mini A',
        details: Text('Lesionada', key: Key('details')),
      ),
    );
    final subtitle = tester.getRect(find.text('Mini A'));
    final details = tester.getRect(find.byKey(const Key('details')));
    final row = tester.getRect(find.byKey(const Key('row')));
    expect(details.top, greaterThanOrEqualTo(subtitle.bottom));
    expect(details.left, subtitle.left);
    expect(row.contains(details.bottomRight - const Offset(1, 1)), isTrue);
  });

  testWidgets('avatar shows the image instead of the initials when given', (
    tester,
  ) async {
    await pumpKit(
      tester,
      InitialsAvatar(
        name: 'Academia Demo',
        image: MemoryImage(kTransparentPng),
      ),
    );
    expect(
      tester.widget<CircleAvatar>(find.byType(CircleAvatar)).foregroundImage,
      isNotNull,
    );
  });
}

/// 1x1 transparent PNG.
final kTransparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
