import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/auth/oidc_auth_service.dart';

/// The Keycloak login theme (`infra/keycloak/themes/hoops/login`, ADR-0022)
/// follows the look chosen in the app: one small script reads the request
/// parameter the app sends. No Node here, so the script is checked as text.
void main() {
  const theme = '../../infra/keycloak/themes/hoops/login';
  final properties = File('$theme/theme.properties').readAsStringSync();
  final script = File('$theme/resources/js/hoops-theme.js');

  test('the theme loads the script', () {
    expect(
      properties,
      contains(RegExp(r'^scripts=js/hoops-theme\.js$', multiLine: true)),
    );
    expect(script.existsSync(), isTrue);
  });

  test('the script reads the parameter the app sends', () {
    expect(loginThemeParameter, 'hoops_theme');
    expect(script.readAsStringSync(), contains("'$loginThemeParameter'"));
  });

  test('only light and dark are ever applied; anything else follows the '
      'browser', () {
    final js = script.readAsStringSync();
    expect(js, contains("value === 'light' || value === 'dark'"));
    expect(js, contains('pf-v5-theme-dark'));
  });

  test('the choice survives the follow-up pages of one sign-in and nothing '
      'longer', () {
    final js = script.readAsStringSync();
    expect(js, contains('sessionStorage'));
    expect(js, isNot(contains('localStorage')));
    expect(js, isNot(contains('document.cookie')));
  });

  test('the script puts nothing from the address into the page', () {
    final js = script.readAsStringSync();
    for (final sink in [
      'innerHTML',
      'outerHTML',
      'document.write',
      'eval(',
      'setAttribute',
      'insertAdjacentHTML',
    ]) {
      expect(js, isNot(contains(sink)), reason: sink);
    }
  });

  test('it holds the look against keycloak.v2 following the browser', () {
    expect(script.readAsStringSync(), contains('MutationObserver'));
  });
}
