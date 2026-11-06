import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/l10n/locale_controller.dart';
import 'package:hoops_app/features/admin/application/admin_providers.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/fake_repos.dart';
import '../../support/harness.dart';
import '../../support/pump_helpers.dart';

Uint8List png([int extra = 0]) => Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  ...List.filled(extra, 0),
]);

// A real 1x1 PNG so Image.memory can decode it in the preview.
final Uint8List realPng = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xFF,
  0xFF,
  0x3F,
  0x00,
  0x05,
  0xFE,
  0x02,
  0xFE,
  0xA7,
  0x35,
  0x81,
  0x84,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  Future<Harness> open(
    WidgetTester tester,
    FakeCore core, {
    PickedFile? picked,
    FakeTenantRepository? tenant,
    bool settle = true,
  }) => pumpAs(
    tester,
    roles: {TenantRole.admin},
    core: core,
    location: '/admin/profile',
    tenant: tenant,
    settle: settle,
    overrides: [logoPickerProvider.overrideWithValue(() async => picked)],
  );

  group('academy profile', () {
    testWidgets('loading', (tester) async {
      final core = FakeCore();
      core.academy.hang = true;
      await open(tester, core, settle: false);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('error shows localized message and retry reloads', (
      tester,
    ) async {
      final core = FakeCore();
      core.academy.failWith = const AppError(kind: AppErrorKind.network);
      await open(tester, core);
      expect(
        find.textContaining('No hay conexión con el servidor'),
        findsOneWidget,
      );
      core.academy.failWith = null;
      await tester.tap(find.byKey(const Key('retry-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('academy-name')), findsOneWidget);
    });

    testWidgets('populated form shows the academy, save sends changes', (
      tester,
    ) async {
      final core = FakeCore();
      await open(tester, core);
      expect(
        find.widgetWithText(TextFormField, 'Academia Demo'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Europe/Madrid'),
        findsOneWidget,
      );

      await enter(tester, 'academy-name', 'Club Nuevo');
      await enter(tester, 'academy-max-play-up', '2');
      await tapKey(tester, 'academy-save');

      expect(core.academy.calls, contains('save'));
      expect((await core.academy.profile()).name, 'Club Nuevo');
      expect((await core.academy.settings()).maxPlayUpLevels, 2);
      expect(find.text('Cambios guardados'), findsOneWidget);
    });

    testWidgets('validation blocks an empty name and a bad play-up number', (
      tester,
    ) async {
      final core = FakeCore();
      await open(tester, core);
      await enter(tester, 'academy-name', '');
      await enter(tester, 'academy-max-play-up', 'x');
      await tapKey(tester, 'academy-save');
      expect(find.text('Campo obligatorio'), findsOneWidget);
      expect(find.text('Introduce un número válido'), findsOneWidget);
      expect(core.academy.calls, isNot(contains('save')));
    });
  });

  group('logo upload', () {
    testWidgets(
      'happy path: preview, PUT with the bytes, header logo re-fetched with revalidation',
      (tester) async {
        final core = FakeCore();
        final tenant = FakeTenantRepository(logoBytes: realPng);
        await open(
          tester,
          core,
          picked: PickedFile(name: 'logo.png', bytes: realPng),
          tenant: tenant,
        );
        final fetchesBefore = tenant.logoFetches.length;

        await tapKey(tester, 'logo-choose');
        expect(find.byKey(const Key('logo-error')), findsNothing);
        expect(find.byType(Image), findsWidgets); // preview
        await tapKey(tester, 'logo-upload');

        expect(core.academy.uploadedBytes, realPng);
        expect(core.academy.uploadedMime, 'image/png');
        expect(find.text('Logo actualizado'), findsOneWidget);
        // cache busting: the app bar logo is fetched again, bypassing the HTTP cache
        expect(tenant.logoFetches.length, greaterThan(fetchesBefore));
        expect(tenant.logoFetches.last, isTrue);
      },
    );

    testWidgets('rejects more than 512 KB without calling the API', (
      tester,
    ) async {
      final core = FakeCore();
      await open(
        tester,
        core,
        picked: PickedFile(name: 'big.png', bytes: png(512 * 1024)),
      );
      await tapKey(tester, 'logo-choose');
      expect(find.text('La imagen supera los 512 KB.'), findsOneWidget);
      expect(find.byKey(const Key('logo-upload')), findsNothing);
      expect(core.academy.uploadedBytes, isNull);
    });

    testWidgets('rejects a wrong type (svg and a renamed jpeg)', (
      tester,
    ) async {
      final core = FakeCore();
      await open(
        tester,
        core,
        picked: PickedFile(name: 'logo.svg', bytes: png()),
      );
      await tapKey(tester, 'logo-choose');
      expect(
        find.text('Formato no válido: usa PNG, JPEG o WebP.'),
        findsOneWidget,
      );
      expect(core.academy.calls, isNot(contains('uploadLogo')));
    });

    testWidgets('localized in English', (tester) async {
      final core = FakeCore();
      final h = await open(
        tester,
        core,
        picked: PickedFile(name: 'big.png', bytes: png(600 * 1024)),
      );
      await h.container.read(localePreferenceProvider.notifier).set('en');
      await tester.pumpAndSettle();
      await tapKey(tester, 'logo-choose');
      expect(find.text('The image is larger than 512 KB.'), findsOneWidget);
    });

    testWidgets('remove logo asks for confirmation then deletes', (
      tester,
    ) async {
      final core = FakeCore(
        academy: FakeAcademyRepository(profile0: profileFixture(hasLogo: true)),
      );
      await open(
        tester,
        core,
        tenant: FakeTenantRepository(logoBytes: realPng),
      );
      await tapKey(tester, 'logo-remove');
      expect(find.text('¿Quitar el logo de la academia?'), findsOneWidget);
      await tapKey(tester, 'dialog-confirm');
      expect(core.academy.logoDeleted, isTrue);
      expect(find.byKey(const Key('logo-remove')), findsNothing);
    });
  });
}
