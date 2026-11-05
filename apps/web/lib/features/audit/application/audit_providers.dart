import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../data/audit_repository.dart';
import '../domain/audit_entry.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) => ApiAuditRepository(ref.watch(api.coreApiProvider)));

/// Whose trail a screen shows: the active academy's, or the platform's (every academy, or [tenantId] only).
class AuditScope {
  const AuditScope.academy() : platform = false, tenantId = null;
  const AuditScope.platform([this.tenantId]) : platform = true;

  final bool platform;
  final String? tenantId;

  @override
  bool operator ==(Object other) => other is AuditScope && other.platform == platform && other.tenantId == tenantId;

  @override
  int get hashCode => Object.hash(platform, tenantId);
}

/// The filters and page of one scope. Changing a filter goes back to the first page.
class AuditQueryNotifier extends Notifier<AuditQuery> {
  AuditQueryNotifier(this.scope);
  final AuditScope scope;

  @override
  AuditQuery build() => const AuditQuery();

  void setRange(DateTime? fromDay, DateTime? toDay) => state = state.withRange(fromDay, toDay);
  void clearRange() => setRange(null, null);
  void setActions(Set<api.AuditAction> actions) => state = state.withActions(actions);
  void nextPage() => state = state.atPage(state.page + 1);
  void previousPage() => state = state.atPage(state.page > 0 ? state.page - 1 : 0);
}

final auditQueryProvider = NotifierProvider.family<AuditQueryNotifier, AuditQuery, AuditScope>(AuditQueryNotifier.new);

/// The page the current query selects, fetched from the server.
final auditPageProvider = FutureProvider.family<AuditPage, AuditScope>((ref, scope) {
  final query = ref.watch(auditQueryProvider(scope));
  final repo = ref.watch(auditRepositoryProvider);
  return scope.platform
      ? repo.platform(query, tenantId: scope.tenantId)
      : repo.academy(ref.watch(api.tenantIdProvider), query);
});
