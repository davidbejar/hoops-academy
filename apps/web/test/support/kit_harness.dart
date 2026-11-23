import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/theme.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';

/// A [MaterialApp] with the app's theme and the four localisation delegates
/// (Spanish, like the app's default, unless [locale] says otherwise): what
/// every test that pumps a widget outside the router needs.
MaterialApp localizedApp({
  required Widget home,
  String locale = 'es',
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildTheme(brightness),
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

/// Pumps a kit widget alone in the app theme (Spanish, like the app's
/// default), on a [size] surface, centred in a page with the canvas colour.
Future<void> pumpKit(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Size size = const Size(360, 240),
  bool scaffold = true,
  String locale = 'es',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    localizedApp(
      brightness: brightness,
      locale: locale,
      home: scaffold
          ? Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Align(alignment: Alignment.topLeft, child: child),
              ),
            )
          : child,
    ),
  );
  await tester.pumpAndSettle();
}

/// Background colour of the nearest decorated box above [finder].
Color? decorationColorOf(WidgetTester tester, Finder finder) {
  for (final box in tester.widgetList<DecoratedBox>(
    find.ancestor(of: finder, matching: find.byType(DecoratedBox)),
  )) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      return decoration.color;
    }
  }
  return null;
}
