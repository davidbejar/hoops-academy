import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/app.dart';
import 'package:hoops_app/core/auth/auth_providers.dart';
import 'package:hoops_app/core/auth/auth_service.dart';
import 'package:hoops_app/core/auth/mock_auth_service.dart';
import 'package:hoops_app/core/storage/preferences.dart';
import 'package:hoops_app/features/landing/application/external_link.dart';
import 'package:hoops_app/features/landing/application/invitation_providers.dart';
import 'package:hoops_app/features/landing/data/invitation_repository.dart';
import 'package:hoops_app/features/landing/domain/invitation_request.dart';
import 'package:hoops_app/features/landing/presentation/landing_screen.dart';
import 'package:hoops_app/features/landing/presentation/widgets/device_frame.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fixtures.dart';
import '../../support/harness.dart';

const _desktop = Size(1280, 800);
const _phone = Size(360, 780);

/// Records the URLs the landing asks to open instead of leaving the page.
class _RecordingLinks implements ExternalLinkOpener {
  final opened = <Uri>[];

  @override
  void open(Uri url) => opened.add(url);
}

/// Records what the form sends and answers [outcome] (the server's part is
/// tested in invitation_repository_test and the core resource tests).
class _FakeInvitations implements InvitationRepository {
  final sent = <InvitationRequest>[];
  InvitationOutcome outcome = InvitationOutcome.sent;

  @override
  Future<InvitationOutcome> send(InvitationRequest request) async {
    sent.add(request);
    return outcome;
  }
}

Future<Harness> _anonymous(
  WidgetTester tester, {
  Size size = _desktop,
  String? locale,
  List<Override> overrides = const [],
  _FakeInvitations? invitations,
}) async {
  final h = Harness(
    me: FakeMeRepository(userWith([tenantNorth])),
    signedIn: false,
    prefs: {'hoops.locale': ?locale},
    extraOverrides: [
      invitationRepositoryProvider.overrideWithValue(
        invitations ?? _FakeInvitations(),
      ),
      ...overrides,
    ],
  );
  await h.pump(tester, size: size);
  return h;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Every section's copy, looked up from the ARB of [l].
List<String> _sectionCopy(AppLocalizations l) => [
  l.landingEyebrow,
  l.landingHeadline,
  l.landingSubheadline,
  l.landingRequestInvitation,
  l.landingSignIn,
  l.landingProofLine,
  l.landingWhyTitle,
  l.landingWhyBody,
  l.landingFeatureRosterTitle,
  l.landingFeatureRosterBody,
  l.landingFeatureStatsTitle,
  l.landingFeatureStatsBody,
  l.landingFeatureTrainingTitle,
  l.landingFeatureTrainingBody,
  l.landingFeatureHealthTitle,
  l.landingFeatureHealthBody,
  l.landingFeatureFamiliesTitle,
  l.landingFeatureFamiliesBody,
  l.landingFeatureAcademiesTitle,
  l.landingFeatureAcademiesBody,
  l.landingRoleAdmin,
  l.landingRoleAdminLine,
  l.landingRoleCoach,
  l.landingRoleCoachLine,
  l.landingRoleParent,
  l.landingRoleParentLine,
  l.landingRolePlayer,
  l.landingRolePlayerLine,
  l.landingCostTitle,
  l.landingCostBody,
  l.landingNextTitle,
  l.landingNextNotificationsTitle,
  l.landingNextNotificationsLine,
  l.landingNextSignupTitle,
  l.landingNextSignupLine,
  l.landingNextIntegrationsTitle,
  l.landingNextIntegrationsLine,
  l.landingNextReportsTitle,
  l.landingNextReportsLine,
  l.landingJoinTitle,
  l.landingJoinIntro,
  l.landingJoinName,
  l.landingJoinEmail,
  l.landingJoinRole,
  l.landingJoinAcademy,
  l.landingJoinSubmit,
  l.landingFooterLicense,
  l.landingFooterSource,
];

/// Opacity of the entrance motion around the (Spanish) hero headline.
double _headlineOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.text(
              'Dirige tu academia como un programa, no como una hoja de cálculo.',
            ),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

void main() {
  group('copy per locale', () {
    // One literal per locale proves the ARB holds the copy file's text; the
    // rest is looked up so every section is checked in every language.
    const headlines = {
      'es': 'Dirige tu academia como un programa, no como una hoja de cálculo.',
      'en': 'Run your academy like a program, not a spreadsheet.',
      'id': 'Kelola akademimu seperti sebuah program, bukan lembar kerja.',
    };
    for (final MapEntry(key: code, value: headline) in headlines.entries) {
      testWidgets('the anonymous root renders every section in $code', (
        tester,
      ) async {
        await _anonymous(tester, locale: code);
        final l = lookupAppLocalizations(Locale(code));

        expect(find.byType(LandingScreen), findsOneWidget);
        expect(find.text(headline), findsOneWidget);
        for (final text in _sectionCopy(l)) {
          expect(find.text(text), findsWidgets, reason: '$code: $text');
        }
        // Language switch: the app's language names.
        for (final name in ['Español', 'English', 'Bahasa Indonesia']) {
          expect(find.text(name), findsOneWidget, reason: name);
        }
      });
    }

    testWidgets('Spanish is the default without a stored choice', (
      tester,
    ) async {
      await _anonymous(tester, size: _phone);
      expect(find.text('Pensado solo para academias de baloncesto'), findsOne);
    });
  });

  group('calls to action', () {
    testWidgets('Sign in opens the login screen; Back returns to the landing', (
      tester,
    ) async {
      await _anonymous(tester, size: _phone);

      await _tap(tester, 'landing-sign-in');
      expect(find.byKey(const Key('login-button')), findsOneWidget);
      expect(find.byType(LandingScreen), findsNothing);

      await _tap(tester, 'login-back');
      expect(find.byType(LandingScreen), findsOneWidget);
    });

    testWidgets('the footer sign-in link opens the login screen too', (
      tester,
    ) async {
      await _anonymous(tester);
      await _tap(tester, 'landing-footer-sign-in');
      expect(find.byKey(const Key('login-button')), findsOneWidget);
    });

    testWidgets('Request an invitation scrolls the form into view', (
      tester,
    ) async {
      await _anonymous(tester, size: _phone);
      final form = find.byKey(const Key('join-form'));
      expect(tester.getRect(form).top, greaterThan(_phone.height));

      await _tap(tester, 'landing-request-invitation');

      final rect = tester.getRect(form);
      expect(rect.top, lessThan(_phone.height));
      expect(rect.bottom, greaterThan(0));
    });

    testWidgets('a signed-in user opening /welcome goes to the app', (
      tester,
    ) async {
      final h = Harness(me: FakeMeRepository(userWith([tenantNorth])));
      await h.pump(tester);
      await h.go(tester, '/welcome');

      expect(find.byType(LandingScreen), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('/welcome is the landing for anonymous visitors', (
      tester,
    ) async {
      final h = await _anonymous(tester, size: _phone);
      await _tap(tester, 'landing-sign-in');
      await h.go(tester, '/welcome');
      expect(find.byType(LandingScreen), findsOneWidget);
    });
  });

  group('invitation request (WP90, ADR-0044)', () {
    testWidgets('an empty request shows the copy\'s validation messages', (
      tester,
    ) async {
      await _anonymous(tester, size: _phone, locale: 'en');
      await _tap(tester, 'join-submit');

      expect(find.text('Enter a valid e-mail'), findsOneWidget);
      expect(find.text('Choose your role'), findsOneWidget);
      expect(find.text("Enter your academy's name"), findsOneWidget);
      expect(find.byKey(const Key('join-confirmation')), findsNothing);
    });

    testWidgets('a malformed e-mail is rejected', (tester) async {
      await _anonymous(tester, size: _phone, locale: 'en');
      await tester.enterText(find.byKey(const Key('join-email')), 'ana@');
      await _tap(tester, 'join-submit');
      expect(find.text('Enter a valid e-mail'), findsOneWidget);
    });

    testWidgets('a valid request is sent, confirmed and the form cleared', (
      tester,
    ) async {
      final invitations = _FakeInvitations();
      await _anonymous(
        tester,
        size: _phone,
        locale: 'en',
        invitations: invitations,
      );
      await tester.enterText(find.byKey(const Key('join-name')), 'Ana Ruiz');
      await tester.enterText(
        find.byKey(const Key('join-email')),
        'ana@club.es',
      );
      await tester.enterText(
        find.byKey(const Key('join-academy')),
        'Club Norte',
      );
      await _tap(tester, 'join-role');
      // The player role is not offered (players never request an academy).
      expect(find.text('Player'), findsOneWidget, reason: 'only the roles row');
      await tester.tap(find.text('Coach').last);
      await tester.pumpAndSettle();
      await _tap(tester, 'join-submit');

      expect(find.byKey(const Key('join-confirmation')), findsOneWidget);
      expect(
        find.text(
          'Thank you. Invitations are being sent by hand during early access; '
          'we will write to you at the address above.',
        ),
        findsOneWidget,
      );
      for (final key in ['join-name', 'join-email', 'join-academy']) {
        final field = tester.widget<TextFormField>(find.byKey(Key(key)));
        expect(field.controller!.text, isEmpty, reason: key);
      }
      expect(find.text('Enter a valid e-mail'), findsNothing);
      expect(find.text('Choose your role'), findsNothing);
      final sent = invitations.sent.single;
      expect(
        (sent.name, sent.email, sent.role, sent.academy, sent.languageCode),
        ('Ana Ruiz', 'ana@club.es', InvitationRole.coach, 'Club Norte', 'en'),
      );
      expect(sent.website, isEmpty, reason: 'no person fills the honeypot');
    });

    Future<void> fillValid(
      WidgetTester tester, {
      String academy = 'Norte',
      String role = 'Academy administrator',
    }) async {
      await tester.enterText(find.byKey(const Key('join-email')), 'a@b.es');
      await tester.enterText(find.byKey(const Key('join-academy')), academy);
      await _tap(tester, 'join-role');
      await tester.tap(find.text(role).last);
      await tester.pumpAndSettle();
    }

    testWidgets('an invalid form sends nothing', (tester) async {
      final invitations = _FakeInvitations();
      await _anonymous(tester, size: _phone, invitations: invitations);
      await _tap(tester, 'join-submit');
      expect(invitations.sent, isEmpty);
    });

    testWidgets('a taken academy name is shown under the academy field until '
        'it changes', (tester) async {
      final invitations = _FakeInvitations()
        ..outcome = InvitationOutcome.academyTaken;
      await _anonymous(
        tester,
        size: _phone,
        locale: 'en',
        invitations: invitations,
      );
      await fillValid(tester, academy: 'Club Norte');
      await _tap(tester, 'join-submit');

      const taken =
          'An academy with this name already exists or has been requested';
      expect(find.text(taken), findsOneWidget);
      expect(find.byKey(const Key('join-confirmation')), findsNothing);
      final email = tester.widget<TextFormField>(
        find.byKey(const Key('join-email')),
      );
      expect(email.controller!.text, 'a@b.es', reason: 'the form is kept');

      invitations.outcome = InvitationOutcome.sent;
      await tester.enterText(find.byKey(const Key('join-academy')), 'Club Sur');
      await _tap(tester, 'join-submit');
      expect(find.text(taken), findsNothing);
      expect(find.byKey(const Key('join-confirmation')), findsOneWidget);
    });

    testWidgets('a request that could not be sent says so and keeps the '
        'values', (tester) async {
      final invitations = _FakeInvitations()
        ..outcome = InvitationOutcome.failed;
      await _anonymous(
        tester,
        size: _phone,
        locale: 'es',
        invitations: invitations,
      );
      await fillValid(tester, role: 'Administrador de la academia');
      await _tap(tester, 'join-submit');

      expect(find.byKey(const Key('join-failed')), findsOneWidget);
      expect(
        find.text(
          'No se ha podido enviar tu solicitud. Inténtalo de nuevo en un '
          'minuto.',
        ),
        findsOneWidget,
      );
      final academy = tester.widget<TextFormField>(
        find.byKey(const Key('join-academy')),
      );
      expect(academy.controller!.text, 'Norte');

      invitations.outcome = InvitationOutcome.sent;
      await _tap(tester, 'join-submit');
      expect(find.byKey(const Key('join-failed')), findsNothing);
      expect(find.byKey(const Key('join-confirmation')), findsOneWidget);
    });

    testWidgets('the honeypot is invisible, unfocusable and outside the '
        'semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      await _anonymous(tester, size: _phone, locale: 'en');
      final honeypot = find.byKey(const Key('join-website'));
      expect(honeypot, findsOneWidget);
      final box = find.ancestor(of: honeypot, matching: find.byType(SizedBox));
      expect(tester.getSize(box.first).height, 0, reason: 'takes no space');
      expect(
        find.ancestor(of: honeypot, matching: find.byType(IgnorePointer)),
        findsWidgets,
      );
      expect(
        find.ancestor(of: honeypot, matching: find.byType(ExcludeFocus)),
        findsWidgets,
      );
      expect(
        find.ancestor(of: honeypot, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      handle.dispose();
    });

    testWidgets('a bot that fills the honeypot sends it along (the server '
        'drops it)', (tester) async {
      final invitations = _FakeInvitations();
      await _anonymous(
        tester,
        size: _phone,
        locale: 'en',
        invitations: invitations,
      );
      await fillValid(tester);
      tester
              .widget<TextField>(find.byKey(const Key('join-website')))
              .controller!
              .text =
          'http://spam.example';
      await _tap(tester, 'join-submit');
      expect(invitations.sent.single.website, 'http://spam.example');
    });

    testWidgets('editing after a confirmation hides it again', (tester) async {
      await _anonymous(tester, size: _phone, locale: 'en');
      await tester.enterText(find.byKey(const Key('join-email')), 'a@b.es');
      await tester.enterText(find.byKey(const Key('join-academy')), 'X');
      await _tap(tester, 'join-role');
      await tester.tap(find.text('Parent').last);
      await tester.pumpAndSettle();
      await _tap(tester, 'join-submit');
      expect(find.byKey(const Key('join-confirmation')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('join-email')), 'b');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('join-confirmation')), findsNothing);
    });
  });

  group('header language switch', () {
    testWidgets('picks a language, re-renders the page and remembers it', (
      tester,
    ) async {
      final h = await _anonymous(tester, size: _phone);
      expect(find.byKey(const Key('landing-header-lang')), findsOneWidget);

      await _tap(tester, 'landing-header-lang');
      await tester.tap(find.byKey(const Key('landing-header-lang-en')));
      await tester.pumpAndSettle();
      expect(
        find.text('Run your academy like a program, not a spreadsheet.'),
        findsOneWidget,
      );
      expect(h.prefs.getString('hoops.locale'), 'en');

      await _tap(tester, 'landing-header-lang');
      await tester.tap(find.byKey(const Key('landing-header-lang-id')));
      await tester.pumpAndSettle();
      expect(find.text('Dibuat khusus untuk akademi basket'), findsOneWidget);
      expect(h.prefs.getString('hoops.locale'), 'id');
    });

    testWidgets('shows the current language code and sits beside sign in', (
      tester,
    ) async {
      await _anonymous(tester, size: _phone, locale: 'id');
      expect(
        find.descendant(
          of: find.byKey(const Key('landing-header-lang')),
          matching: find.text('ID'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('landing-header-sign-in')), findsOneWidget);
    });

    testWidgets('the screenshots follow the language (fallback en)', (
      tester,
    ) async {
      await _anonymous(tester, size: _phone, locale: 'id');
      final assets = tester
          .widgetList<Image>(find.byType(Image))
          .map((i) => (i.image as AssetImage).assetName)
          .toSet();
      expect(assets, isNotEmpty);
      expect(assets.every((a) => a.endsWith('_id.png')), isTrue);
      expect(
        LandingShot.liveMatch.assetFor('fr'),
        endsWith('live_match_en.png'),
      );
      expect(
        LandingShot.liveMatch.assetFor('es'),
        endsWith('live_match_es.png'),
      );
    });
  });

  group('header theme switch', () {
    testWidgets('picks light, dark or system, remembers it and applies it', (
      tester,
    ) async {
      final h = await _anonymous(tester, size: _phone);
      expect(find.byKey(const Key('landing-header-theme')), findsOneWidget);

      Brightness shown() =>
          Theme.of(tester.element(find.byType(LandingScreen))).brightness;

      await _tap(tester, 'landing-header-theme');
      await tester.tap(find.byKey(const Key('landing-header-theme-dark')));
      await tester.pumpAndSettle();
      expect(shown(), Brightness.dark);
      expect(h.prefs.getString('hoops.themeMode'), 'dark');

      await _tap(tester, 'landing-header-theme');
      await tester.tap(find.byKey(const Key('landing-header-theme-light')));
      await tester.pumpAndSettle();
      expect(shown(), Brightness.light);
      expect(h.prefs.getString('hoops.themeMode'), 'light');

      await _tap(tester, 'landing-header-theme');
      await tester.tap(find.byKey(const Key('landing-header-theme-system')));
      await tester.pumpAndSettle();
      expect(h.prefs.getString('hoops.themeMode'), 'system');
    });
  });

  group('footer', () {
    testWidgets('the language switch re-renders the page and remembers it', (
      tester,
    ) async {
      final h = await _anonymous(tester);
      await _tap(tester, 'landing-lang-en');

      expect(
        find.text('Run your academy like a program, not a spreadsheet.'),
        findsOneWidget,
      );
      expect(h.prefs.getString('hoops.locale'), 'en');

      await _tap(tester, 'landing-lang-id');
      expect(find.text('Dibuat khusus untuk akademi basket'), findsOneWidget);
    });

    testWidgets('the source link opens the GitHub repository', (tester) async {
      final links = _RecordingLinks();
      await _anonymous(
        tester,
        overrides: [externalLinkOpenerProvider.overrideWithValue(links)],
      );
      await _tap(tester, 'landing-source-link');
      expect(links.opened, [
        Uri.parse('https://github.com/davidbejar/hoops-academy'),
      ]);
    });

    testWidgets('there is no privacy link (no policy page exists yet)', (
      tester,
    ) async {
      await _anonymous(tester, locale: 'en');
      expect(find.text('Privacy'), findsNothing);
    });
  });

  group('root gate and motion', () {
    testWidgets('while auth initialises the root shows the splash', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = MockAuthService(initial: AuthStatus.unknown);
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HoopsApp(),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LandingScreen), findsNothing);

      await auth.expireSession(); // resolves to "signed out"
      await tester.pumpAndSettle();
      expect(find.byType(LandingScreen), findsOneWidget);
    });

    testWidgets('with reduced motion the hero is fully visible at once', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _anonymous(tester, size: _phone);
      // Inspect the first frames of a fresh landing.
      await _tap(tester, 'landing-sign-in');
      await tester.tap(find.byKey(const Key('login-back')));
      await tester.pump();
      await tester.pump();

      expect(_headlineOpacity(tester), 1);
    });

    testWidgets('with motion the hero fades in', (tester) async {
      await _anonymous(tester, size: _phone);
      await _tap(tester, 'landing-sign-in');
      await tester.tap(find.byKey(const Key('login-back')));
      await tester.pump();
      await tester.pump();

      expect(_headlineOpacity(tester), lessThan(1));
      await tester.pumpAndSettle();
      expect(_headlineOpacity(tester), 1);
    });
  });
}
