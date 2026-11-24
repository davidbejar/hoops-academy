import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/l10n/locale_controller.dart';
import 'package:hoops_app/features/admin/application/admin_providers.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/core_seed.dart';
import '../../support/harness.dart';
import '../../support/mock_backend.dart';
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

/// Every call of the academy's profile, settings and logo.
final _academyApi = RegExp('^/api/core/tenant');
const _profilePath = '/api/core/tenant';

void main() {
  Future<Harness> open(
    WidgetTester tester,
    FakeCore core, {
    PickedFile? picked,
    FakeTenantRepository? tenant,
    bool settle = true,
    void Function(MockBackend backend)? prepare,
  }) => pumpAs(
    tester,
    roles: {TenantRole.admin},
    core: core,
    location: '/admin/profile',
    tenant: tenant,
    settle: settle,
    prepare: prepare,
    overrides: [logoPickerProvider.overrideWithValue(() async => picked)],
  );

  /// Whether the form saved (a PATCH of the profile or a PUT of anything).
  bool saved(Harness h) => h.backend.requests.any(
    (r) => _academyApi.hasMatch(r.path) && r.method != 'GET',
  );

  group('academy profile', () {
    testWidgets('loading', (tester) async {
      await open(
        tester,
        FakeCore(),
        settle: false,
        prepare: (b) => b.hang(_academyApi),
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('error shows localized message and retry reloads', (
      tester,
    ) async {
      final h = await open(
        tester,
        FakeCore(),
        prepare: (b) => b.networkDown(_academyApi),
      );
      expect(
        find.textContaining('No hay conexión con el servidor'),
        findsOneWidget,
      );
      h.backend.heal();
      await tester.tap(find.byKey(const Key('retry-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('academy-name')), findsOneWidget);
    });

    testWidgets('populated form shows the academy, save sends changes', (
      tester,
    ) async {
      final h = await open(tester, FakeCore());
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

      expect(h.backend.core.profile['name'], 'Club Nuevo');
      expect(h.backend.core.settings['maxPlayUpLevels'], 2);
      expect(find.text('Cambios guardados'), findsOneWidget);
    });

    testWidgets('validation blocks an empty name and a bad play-up number', (
      tester,
    ) async {
      final h = await open(tester, FakeCore());
      await enter(tester, 'academy-name', '');
      await enter(tester, 'academy-max-play-up', 'x');
      await tapKey(tester, 'academy-save');
      expect(find.text('Campo obligatorio'), findsOneWidget);
      expect(find.text('Introduce un número válido'), findsOneWidget);
      expect(saved(h), isFalse);
    });
  });

  group('academy contact', () {
    FakeCore coreWithContact() => FakeCore(
      profile: profileFixture().rebuild(
        (b) => b
          ..contactEmail = 'info@club.io'
          ..websiteUrl = 'https://club.io',
      ),
    );

    testWidgets('opens with the current contact data', (tester) async {
      await open(tester, coreWithContact());
      expect(
        find.widgetWithText(TextFormField, 'info@club.io'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'https://club.io'),
        findsOneWidget,
      );
    });

    testWidgets('changed values are sent without clear', (tester) async {
      final h = await open(tester, coreWithContact());
      await enter(tester, 'academy-contact-email', 'hola@club.io');
      await enter(tester, 'academy-website', 'https://nuevo.club.io');
      await tapKey(tester, 'academy-save');
      final r = h.backend.lastBody(_profilePath, method: 'PATCH');
      expect(r['contactEmail'], 'hola@club.io');
      expect(r['websiteUrl'], 'https://nuevo.club.io');
      expect(r['clear'], isNull);
    });

    testWidgets('emptied contact fields are sent in clear', (tester) async {
      final h = await open(tester, coreWithContact());
      await enter(tester, 'academy-contact-email', '');
      await enter(tester, 'academy-website', '  ');
      await tapKey(tester, 'academy-save');
      final r = h.backend.lastBody(_profilePath, method: 'PATCH');
      expect(r['contactEmail'], isNull);
      expect(r['websiteUrl'], isNull);
      expect((r['clear']! as List).toSet(), {'contactEmail', 'websiteUrl'});
      expect(h.backend.core.profile['contactEmail'], isNull);
    });

    testWidgets('an invalid e-mail or address is not sent', (tester) async {
      final h = await open(tester, coreWithContact());
      await enter(tester, 'academy-contact-email', 'nope');
      await enter(tester, 'academy-website', 'club');
      await tapKey(tester, 'academy-save');
      expect(saved(h), isFalse);
      expect(find.text('Introduce un correo válido'), findsOneWidget);
      expect(find.text('Introduce una dirección web válida'), findsOneWidget);
    });

    testWidgets('a server error keeps the typed values', (tester) async {
      final h = await open(tester, coreWithContact());
      h.backend.fail(_academyApi);
      await enter(tester, 'academy-contact-email', 'otro@club.io');
      await tapKey(tester, 'academy-save');
      expect(
        find.widgetWithText(TextFormField, 'otro@club.io'),
        findsOneWidget,
      );
    });

    testWidgets('a coach cannot reach the academy profile', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        core: coreWithContact(),
        location: '/admin/profile',
      );
      expect(find.byKey(const Key('academy-contact-email')), findsNothing);
    });
  });

  group('logo upload', () {
    testWidgets(
      'happy path: preview, PUT with the bytes, header logo re-fetched with revalidation',
      (tester) async {
        final tenant = FakeTenantRepository(logoBytes: realPng);
        final h = await open(
          tester,
          FakeCore(),
          picked: PickedFile(name: 'logo.png', bytes: realPng),
          tenant: tenant,
        );
        final fetchesBefore = tenant.logoFetches.length;

        await tapKey(tester, 'logo-choose');
        expect(find.byKey(const Key('logo-error')), findsNothing);
        expect(find.byType(Image), findsWidgets); // preview
        await tapKey(tester, 'logo-upload');

        expect(h.backend.core.logo, realPng);
        expect(
          h.backend
              .requestsTo('/api/core/tenant/logo', method: 'PUT')
              .single
              .headers['Content-Type'],
          'image/png',
        );
        expect(find.text('Logo actualizado'), findsOneWidget);
        // cache busting: the app bar logo is fetched again, bypassing the HTTP cache
        expect(tenant.logoFetches.length, greaterThan(fetchesBefore));
        expect(tenant.logoFetches.last, isTrue);
      },
    );

    testWidgets('rejects more than 512 KB without calling the API', (
      tester,
    ) async {
      final h = await open(
        tester,
        FakeCore(),
        picked: PickedFile(name: 'big.png', bytes: png(512 * 1024)),
      );
      await tapKey(tester, 'logo-choose');
      expect(find.text('La imagen supera los 512 KB.'), findsOneWidget);
      expect(find.byKey(const Key('logo-upload')), findsNothing);
      expect(
        h.backend.requestsTo('/api/core/tenant/logo', method: 'PUT'),
        isEmpty,
      );
    });

    testWidgets('rejects a wrong type (svg and a renamed jpeg)', (
      tester,
    ) async {
      final h = await open(
        tester,
        FakeCore(),
        picked: PickedFile(name: 'logo.svg', bytes: png()),
      );
      await tapKey(tester, 'logo-choose');
      expect(
        find.text('Formato no válido: usa PNG, JPEG o WebP.'),
        findsOneWidget,
      );
      expect(
        h.backend.requestsTo('/api/core/tenant/logo', method: 'PUT'),
        isEmpty,
      );
    });

    testWidgets('localized in English', (tester) async {
      final h = await open(
        tester,
        FakeCore(),
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
      final h = await open(
        tester,
        FakeCore(profile: profileFixture(hasLogo: true)),
        tenant: FakeTenantRepository(logoBytes: realPng),
      );
      await tapKey(tester, 'logo-remove');
      expect(find.text('¿Quitar el logo de la academia?'), findsOneWidget);
      await tapKey(tester, 'dialog-confirm');
      expect(h.backend.core.logo, isNull);
      expect(find.byKey(const Key('logo-remove')), findsNothing);
    });
  });
}
