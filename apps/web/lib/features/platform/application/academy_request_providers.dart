import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../data/academy_request_repository.dart';
import 'platform_providers.dart';

final academyRequestRepositoryProvider = Provider<AcademyRequestRepository>(
  (ref) => ApiAcademyRequestRepository(ref.watch(api.coreApiProvider)),
);

/// The workbench tab being shown (pending first).
class AcademyRequestTabNotifier extends Notifier<api.AcademyRequestStatus> {
  @override
  api.AcademyRequestStatus build() => api.AcademyRequestStatus.PENDING;
  void set(api.AcademyRequestStatus status) => state = status;
}

final academyRequestTabProvider =
    NotifierProvider<AcademyRequestTabNotifier, api.AcademyRequestStatus>(
      AcademyRequestTabNotifier.new,
    );

/// The requests of one status. A decision reloads every status and the academy list.
class AcademyRequestsNotifier extends AsyncNotifier<List<api.AcademyRequest>> {
  AcademyRequestsNotifier(this.status);
  final api.AcademyRequestStatus status;

  AcademyRequestRepository get _repo =>
      ref.read(academyRequestRepositoryProvider);

  @override
  Future<List<api.AcademyRequest>> build() =>
      ref.watch(academyRequestRepositoryProvider).list(status);

  /// The result carries the temporary password of a new login: the caller shows it once and drops it; it is never
  /// put into any provider's state.
  Future<api.AcademyRequestAccepted> accept(
    String requestId,
    api.AcceptAcademyRequest request,
  ) async {
    final accepted = await _repo.accept(requestId, request);
    await _reload();
    return accepted;
  }

  Future<api.AcademyRequest> reject(String requestId, String reason) async {
    final rejected = await _repo.reject(requestId, reason);
    await _reload();
    return rejected;
  }

  Future<void> _reload() async {
    ref.invalidate(academyRequestsProvider);
    ref.invalidate(tenantsProvider);
    await future;
  }
}

final academyRequestsProvider =
    AsyncNotifierProvider.family<
      AcademyRequestsNotifier,
      List<api.AcademyRequest>,
      api.AcademyRequestStatus
    >(AcademyRequestsNotifier.new);

/// How many requests wait for a decision (the badge of the hub and of the
/// navigation); null while unknown or when the list cannot be loaded.
final pendingRequestsCountProvider = Provider<int?>(
  (ref) => ref
      .watch(academyRequestsProvider(api.AcademyRequestStatus.PENDING))
      .value
      ?.length,
);
