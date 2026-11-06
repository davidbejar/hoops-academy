import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// The `email` claim of a JWT access token (null when absent or not a JWT).
String? emailFromAccessToken(String? token) {
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final claims = jsonDecode(payload);
    final email = claims is Map ? claims['email'] : null;
    return email is String && email.isNotEmpty ? email : null;
  } on FormatException {
    return null;
  }
}

/// The e-mail the identity provider signed the user in with.
final FutureProvider<String?> signedInEmailProvider = FutureProvider<String?>(
  (ref) async =>
      emailFromAccessToken(await ref.watch(authServiceProvider).accessToken()),
);
