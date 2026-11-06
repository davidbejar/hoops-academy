import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// The `email` claim of a JWT access token (null when absent or not a JWT).
String? emailFromAccessToken(String? token) => _stringClaim(token, 'email');

/// The `sub` claim of a JWT access token (null when absent or not a JWT).
String? subjectFromAccessToken(String? token) => _stringClaim(token, 'sub');

String? _stringClaim(String? token, String name) {
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final claims = jsonDecode(payload);
    final value = claims is Map ? claims[name] : null;
    return value is String && value.isNotEmpty ? value : null;
  } on FormatException {
    return null;
  }
}

/// The e-mail the identity provider signed the user in with.
final FutureProvider<String?> signedInEmailProvider = FutureProvider<String?>(
  (ref) async =>
      emailFromAccessToken(await ref.watch(authServiceProvider).accessToken()),
);
