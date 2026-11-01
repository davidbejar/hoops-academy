/// The generated core client plus the `Date` type it does not export.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_core_api/hoops_core_api.dart' as gen;
import 'package:hoops_core_api/hoops_core_api.dart' hide Locale;

import '../http/dio_provider.dart';
import '../session/session_providers.dart';

export 'package:hoops_core_api/hoops_core_api.dart' hide Locale;
export 'package:hoops_core_api/src/model/date.dart' show Date;

/// The contract's `Locale` (es / en / id); avoids Flutter's `Locale`.
typedef ApiLocale = gen.Locale;

/// Generated client on the app's shared [Dio] (its own interceptors are off).
final coreApiProvider = Provider<HoopsCoreApi>(
  (ref) => HoopsCoreApi(dio: ref.watch(dioProvider), interceptors: const []),
);

/// The active tenant id every repository call is scoped to.
final tenantIdProvider = Provider<String>((ref) {
  final id = ref.watch(activeTenantIdProvider);
  if (id == null) throw StateError('no active tenant');
  return id;
});
