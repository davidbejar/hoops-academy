import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/http/dio_provider.dart';
import '../data/me_repository.dart';
import '../domain/current_user.dart';

final Provider<MeRepository> meRepositoryProvider = Provider<MeRepository>(
  (ref) => ApiMeRepository(ref.watch(dioProvider)),
);

/// `GET /api/core/me`, only while signed in (so a sign-out drops the data).
final FutureProvider<CurrentUser> currentUserProvider =
    FutureProvider<CurrentUser>((ref) async {
      final status = ref.watch(authStatusProvider);
      if (status != AuthStatus.authenticated) {
        throw StateError('not authenticated');
      }
      return ref.watch(meRepositoryProvider).fetch();
    });
