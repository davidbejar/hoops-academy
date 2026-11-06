import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/theme.dart';
import 'package:hoops_app/core/ui/temporary_password_dialog.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';

const _password = 'test-temp-password-1';

/// A bare app with one button that announces a login, so the dialog is tested on its own.
Future<void> _pump(
  WidgetTester tester, {
  String? temporaryPassword = _password,
  String? email = 'ada@example.org',
  String locale = 'es',
  Size size = const Size(360, 780),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.light),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const Key('open'),
              onPressed: () => announceLogin(
                context,
                person: 'Ada Lovelace',
                email: email,
                temporaryPassword: temporaryPassword,
                done: 'Administrador añadido',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
}

void main() {
  group('temporary password dialog', () {
    testWidgets(
      'shows the password once in a selectable monospace field with the person and the sign-in e-mail',
      (tester) async {
        await _pump(tester);
        await _open(tester);
        expect(find.byKey(const Key('temp-password-dialog')), findsOneWidget);
        final value = tester.widget<SelectableText>(
          find.byKey(const Key('temp-password-value')),
        );
        expect(value.data, _password);
        expect(value.style?.fontFamily, 'monospace');
        expect(find.textContaining('Ada Lovelace'), findsOneWidget);
        expect(find.textContaining('ada@example.org'), findsOneWidget);
      },
    );

    testWidgets(
      'explains: share privately, shown only now, own password at the first sign-in; promises no e-mail',
      (tester) async {
        await _pump(tester);
        await _open(tester);
        expect(find.textContaining('canal privado'), findsOneWidget);
        expect(find.textContaining('Solo se muestra ahora'), findsOneWidget);
        expect(find.textContaining('debe elegir la suya'), findsOneWidget);
        expect(
          find.textContaining('No se envía ningún correo'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'copy puts exactly the password on the clipboard and confirms',
      (tester) async {
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData')
              copied = (call.arguments as Map)['text'] as String?;
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await _pump(tester);
        await _open(tester);
        await tester.tap(find.byKey(const Key('temp-password-copy')));
        await tester.pump();
        expect(copied, _password);
        expect(find.text('Contraseña copiada'), findsOneWidget);
      },
    );

    testWidgets(
      'only an explicit Done closes it: no cancel button, the barrier and back do not dismiss',
      (tester) async {
        await _pump(tester);
        await _open(tester);
        expect(find.byKey(const Key('form-cancel')), findsNothing);
        await tester.tapAt(const Offset(4, 4)); // barrier
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('temp-password-dialog')), findsOneWidget);
        await tester.binding.handlePopRoute(); // system back
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('temp-password-dialog')), findsOneWidget);
        await tester.tap(find.byKey(const Key('temp-password-done')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
      },
    );

    testWidgets('after Done the password is nowhere in the widget tree', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester);
      expect(find.text(_password), findsOneWidget);
      await tester.tap(find.byKey(const Key('temp-password-done')));
      await tester.pumpAndSettle();
      expect(find.text(_password), findsNothing);
      expect(find.textContaining(_password), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is SelectableText && w.data == _password,
        ),
        findsNothing,
      );
    });

    testWidgets(
      'without an e-mail (approvals) the person is named and no address line shows',
      (tester) async {
        await _pump(tester, email: null);
        await _open(tester);
        expect(find.textContaining('Ada Lovelace'), findsOneWidget);
        expect(find.textContaining('ada@example.org'), findsNothing);
        expect(find.byKey(const Key('temp-password-value')), findsOneWidget);
      },
    );

    testWidgets(
      'no temporary password (existing login): no dialog, a snack bar says to use the existing password',
      (tester) async {
        await _pump(tester, temporaryPassword: null);
        await _open(tester);
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
        expect(find.textContaining('Administrador añadido'), findsOneWidget);
        expect(find.textContaining('contraseña actual'), findsOneWidget);
      },
    );

    for (final (locale, title, done) in [
      ('en', 'Temporary password', 'Done'),
      ('id', 'Kata sandi sementara', 'Selesai'),
    ]) {
      testWidgets('is localised ($locale)', (tester) async {
        await _pump(tester, locale: locale);
        await _open(tester);
        expect(find.text(title), findsOneWidget);
        expect(find.text(done), findsOneWidget);
      });
    }

    testWidgets(
      'fits 360 px wide with the long password and e-mail, and scrolls on a short screen',
      (tester) async {
        await _pump(
          tester,
          email:
              'a-very-long-address.of.somebody@a-long-academy-name.example.org',
          size: const Size(360, 400),
        );
        await _open(tester);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(const Key('temp-password-done')));
        expect(find.byKey(const Key('temp-password-done')), findsOneWidget);
      },
    );
  });
}
