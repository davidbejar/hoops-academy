import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-request ambient values (active tenant, UI language) read by the HTTP
/// interceptors.
///
/// It is a plain mutable holder, published by `HoopsApp`, rather than providers
/// the Dio provider would watch: the profile/`/me` providers *use* Dio, so
/// Dio depending on them back would be a provider cycle.
class RequestContext {
  String? tenantId;
  String languageCode = 'es';
}

final requestContextProvider = Provider<RequestContext>(
  (ref) => RequestContext(),
);
