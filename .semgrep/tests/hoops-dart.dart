// Fixtures for `semgrep --test --config .semgrep/rules .semgrep/tests` (never compiled).
import 'dart:io';

void tabs(Uri url) {
  // ruleid: hoops-dart-window-open-without-noopener
  _open(url.toString(), '_blank');
  // ruleid: hoops-dart-window-open-without-noopener
  _open(url.toString(), '_blank', 'noreferrer');
  // ok: hoops-dart-window-open-without-noopener
  _open(url.toString(), '_blank', 'noopener,noreferrer');
  // ok: hoops-dart-window-open-without-noopener
  _open(url.toString(), '_self', '');
}

Future<void> prefs(SharedPreferences prefs, String accessToken, String tenantId) async {
  // ruleid: hoops-dart-secret-in-preferences
  await prefs.setString('hoops.access_token', accessToken);
  // ruleid: hoops-dart-secret-in-preferences
  await prefs.setString('hoops.session', accessToken);
  // ok: hoops-dart-secret-in-preferences
  await prefs.setString('hoops.tenant', tenantId);
}

void html(dynamic element, dynamic document, String userText) {
  // ruleid: hoops-dart-unsafe-html
  element.innerHTML = userText;
  // ruleid: hoops-dart-unsafe-html
  element.setInnerHtml(userText);
  // ruleid: hoops-dart-unsafe-html
  document.write(userText);
  // ok: hoops-dart-unsafe-html
  element.textContent = userText;
  // ok: hoops-dart-unsafe-html
  StringBuffer().write(userText);
}

void logs(String refreshToken, String name, Logger logger) {
  // ruleid: hoops-dart-print-secret
  print('refreshed: $refreshToken');
  // ruleid: hoops-dart-print-secret
  debugPrint('password=' + name);
  // ruleid: hoops-dart-print-secret
  logger.warning('token refresh failed for $refreshToken');
  // ok: hoops-dart-print-secret
  debugPrint('signed in as $name');
  // ok: hoops-dart-print-secret
  logger.info('token refresh failed');
}

void tls(HttpClient client) {
  // ruleid: hoops-dart-tls-bypass
  client.badCertificateCallback = (cert, host, port) => true;
  // ok: hoops-dart-tls-bypass
  client.connectionTimeout = const Duration(seconds: 5);
}
