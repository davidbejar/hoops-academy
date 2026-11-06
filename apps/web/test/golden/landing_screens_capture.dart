// Captures the landing page's device mock-ups (WP70) from the demo mock with the golden toolchain, in real fonts.
//
//   flutter test test/golden/landing_screens_capture.dart            # writes assets/landing/*.png
//   HOOPS_CAPTURE_LANDING=1 flutter test test/golden/landing_screens_capture.dart   # also full-page pictures of the landing
//                                                                            # (light/dark, phone/desktop) in build/landing_review/
//
// The whole app runs in mock mode (in-memory core, game and athlete APIs; the data of lib/core/mock), signed in as the
// demo user (ADMIN + COACH of Academia Demo, platform super admin), Spanish UI, 360x780 logical at 2x. Roboto and the
// Material icons come from the Flutter SDK cache, so the pictures show real text instead of the test font's boxes.
// Not part of `flutter test` (no `_test.dart` suffix, so it is never picked up); rerun it when a captured screen changes visibly.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/app.dart';
import 'package:hoops_app/app/feature_modules.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/core/config/app_config.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/core/storage/preferences.dart';
import 'package:hoops_app/features/match/application/match_providers.dart';
import 'package:hoops_app/features/match/data/local/match_database.dart';
import 'package:hoops_app/features/match/data/local/match_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _liveMatch = '0190b6a0-0000-7000-8000-00000000c001';
const _logical = Size(360, 780);
const _pixelRatio = 2.0;

Future<void> _loadFonts() async {
  final sdk = File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent
      .parent
      .parent
      .parent
      .path;
  final candidates = [
    '${Platform.environment['FLUTTER_ROOT'] ?? ''}/bin/cache/artifacts/material_fonts',
    '$sdk/bin/cache/artifacts/material_fonts',
    '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts',
  ];
  final dir = candidates
      .map(Directory.new)
      .firstWhere(
        (d) => File('${d.path}/Roboto-Regular.ttf').existsSync(),
        orElse: () => throw StateError(
          'Roboto not found; set FLUTTER_ROOT (tried $candidates)',
        ),
      );
  ByteData read(String name) =>
      ByteData.sublistView(File('${dir.path}/$name').readAsBytesSync());
  final roboto = FontLoader('Roboto');
  for (final weight in ['Light', 'Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(Future.value(read('Roboto-$weight.ttf')));
  }
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(read('MaterialIcons-Regular.otf')))).load();
}

Future<void> _save(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final image = await captureImage(
      find.byType(MaterialApp).evaluate().single,
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(png!.buffer.asUint8List());
    // ignore: avoid_print
    print(
      'wrote $path (${image.width}x${image.height}, ${png.lengthInBytes ~/ 1024} KiB)',
    );
  });
}

/// Pumps frames for [duration] without waiting to settle (the live match has a running clock).
Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = tester.binding.clock.now().add(duration);
  while (tester.binding.clock.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The whole app in mock mode, signed out, at [logical] size.
Future<ProviderContainer> _mockApp(
  WidgetTester tester,
  Size logical,
  double pixelRatio,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final store = MatchStore(
    MatchDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    ),
  );
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      matchStoreProvider.overrideWithValue(store),
      appConfigProvider.overrideWithValue(
        AppConfig(
          issuer: Uri.parse('http://unused'),
          clientId: 'web',
          apiBase: 'http://mock.local',
          mockApi: true,
          scopes: const ['openid'],
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = logical * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const HoopsApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });
  testWidgets('capture the landing screenshots from the demo mock', (
    tester,
  ) async {
    await tester.runAsync(
      () => Future.wait([
        for (final m in featureModules.values) ...[
          m.load(),
          for (final sub in m.subPages) sub.load(),
        ],
      ]),
    );
    final container = await _mockApp(tester, _logical, _pixelRatio);
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenant-$mockTenantAId')));
    await tester.pumpAndSettle();

    Future<void> go(String location) async {
      container.read(routerProvider).go(location);
      await tester.pumpAndSettle();
    }

    await go('/training');
    await _save(tester, 'assets/landing/training_week.png');

    await go('/players/p-leo/health');
    await _save(tester, 'assets/landing/player_health.png');

    await go('/platform/$mockTenantAId');
    await tester.scrollUntilVisible(find.byKey(const Key('usage-trend')), 300);
    await tester.pumpAndSettle();
    // The usage trend chart near the top, the per-module counters above it.
    final trend = tester.element(find.byKey(const Key('usage-trend')));
    await tester.runAsync(
      () => Scrollable.ensureVisible(trend, alignment: 0.35),
    );
    await tester.pumpAndSettle();
    await _save(tester, 'assets/landing/platform_usage.png');

    container.read(routerProvider).go('/matches/$_liveMatch');
    await _pumpFor(tester, const Duration(seconds: 3));
    await _save(tester, 'assets/landing/live_match.png');

    // Leave the live screen so its timers stop before the test ends.
    container.read(routerProvider).go('/training');
    await _pumpFor(tester, const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    container.dispose(); // stops the match sync worker's timers
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('review pictures of the whole landing', (tester) async {
    const dir = 'build/landing_review';
    Directory(dir).createSync(recursive: true);
    for (final brightness in Brightness.values) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      for (final size in const [Size(360, 9000), Size(1280, 5000)]) {
        await _mockApp(tester, size, 1);
        await _save(
          tester,
          '$dir/landing_${size.width.toInt()}_${brightness.name}.png',
        );
      }
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  }, skip: Platform.environment['HOOPS_CAPTURE_LANDING'] != '1');
}
