import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/design/tokens.dart';
import 'package:hoops_app/core/ui/page_layout.dart';

import '../../support/kit_harness.dart';

void main() {
  testWidgets('PageHeader: eyebrow, title as a header, subtitle, actions', (
    tester,
  ) async {
    await pumpKit(
      tester,
      PageHeader(
        eyebrow: 'Temporada 2026/27',
        title: 'Equipos',
        subtitle: '6 equipos',
        actions: [FilledButton(onPressed: () {}, child: const Text('Nuevo'))],
      ),
    );
    expect(find.text('Temporada 2026/27'), findsOneWidget);
    expect(find.text('6 equipos'), findsOneWidget);
    expect(find.text('Nuevo'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Equipos'));
    expect(title.style!.fontWeight, FontWeight.w800);
    final header = tester.widget<Semantics>(
      find
          .ancestor(of: find.text('Equipos'), matching: find.byType(Semantics))
          .first,
    );
    expect(header.properties.header, isTrue);
  });

  testWidgets('PageHeader puts actions under the title on phones', (
    tester,
  ) async {
    await pumpKit(
      tester,
      PageHeader(
        title: 'Equipos',
        actions: [
          FilledButton(
            key: const Key('new'),
            onPressed: () {},
            child: const Text('Nuevo'),
          ),
        ],
      ),
      size: const Size(360, 300),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('new'))).dy,
      greaterThan(tester.getBottomLeft(find.text('Equipos')).dy),
    );
  });

  testWidgets('PageHeader puts actions beside the title on desktops', (
    tester,
  ) async {
    await pumpKit(
      tester,
      SizedBox(
        width: 900,
        child: PageHeader(
          title: 'Equipos',
          actions: [
            FilledButton(
              key: const Key('new'),
              onPressed: () {},
              child: const Text('Nuevo'),
            ),
          ],
        ),
      ),
      size: const Size(1024, 300),
    );
    expect(
      tester.getCenter(find.byKey(const Key('new'))).dy,
      closeTo(tester.getCenter(find.text('Equipos')).dy, 12),
    );
  });

  for (final (width, gutter) in [
    (360.0, HoopsSpace.md),
    (800.0, HoopsSpace.lg),
    (1280.0, HoopsSpace.xl),
  ]) {
    testWidgets('ContentFrame uses the $gutter px gutter at $width px', (
      tester,
    ) async {
      await pumpKit(
        tester,
        const ContentFrame(child: SizedBox(key: Key('c'), height: 10)),
        size: Size(width, 200),
        scaffold: false,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('c'))).dx,
        greaterThanOrEqualTo(gutter),
      );
      expect(
        tester.getSize(find.byKey(const Key('c'))).width,
        lessThanOrEqualTo(WidthClass.readingMax),
      );
    });
  }

  testWidgets('PageBody: header, sections with the section gap, scrolls', (
    tester,
  ) async {
    await pumpKit(
      tester,
      const PageBody(
        header: PageHeader(title: 'Inicio'),
        children: [
          SizedBox(key: Key('one'), height: 300),
          SizedBox(key: Key('two'), height: 300),
        ],
      ),
      size: const Size(360, 500),
      scaffold: false,
    );
    expect(find.text('Inicio'), findsOneWidget);
    final one = tester.getRect(find.byKey(const Key('one')));
    final two = tester.getRect(find.byKey(const Key('two')));
    expect(two.top - one.bottom, WidthClass.compact.sectionGap);
    await tester.drag(find.byType(Scrollable), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const Key('two'))).top, lessThan(two.top));
  });

  testWidgets('PageBody stretches a section narrower than the frame', (
    tester,
  ) async {
    await pumpKit(
      tester,
      const PageBody(
        header: PageHeader(key: Key('head'), title: 'Inicio'),
        children: [Text('corto', key: Key('short'))],
      ),
      size: const Size(360, 500),
      scaffold: false,
    );
    final gutter = WidthClass.compact.gutter;
    expect(
      tester.getSize(find.byKey(const Key('head'))).width,
      360 - 2 * gutter,
    );
    expect(tester.getTopLeft(find.byKey(const Key('short'))).dx, gutter);
  });
}
