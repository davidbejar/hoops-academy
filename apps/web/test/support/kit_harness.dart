import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/theme.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';

/// Pumps a kit widget alone in the app theme (Spanish, like the app's
/// default), on a [size] surface, centred in a page with the canvas colour.
Future<void> pumpKit(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Size size = const Size(360, 240),
  bool scaffold = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(brightness),
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
