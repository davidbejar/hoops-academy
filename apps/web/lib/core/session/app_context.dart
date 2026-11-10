import '../../features/me/domain/current_user.dart';

/// The remembered-context value of "Application admin" (an academy is
/// remembered by its tenant id, a UUID, so the two cannot collide).
const platformContextId = 'platform';

/// A place the login can work in (WP99, decision 71): one of its academies or,
/// for a super admin, the application admin. Each has its own menu. The server
/// stays the authority; the web only decides which menus to show.
sealed class AppContext {
  const AppContext();

  /// What is remembered per browser to reopen this context.
  String get id;
}

final class AcademyContext extends AppContext {
  const AcademyContext(this.membership);

  final TenantMembership membership;

  @override
  String get id => membership.tenantId;
}

final class ApplicationAdminContext extends AppContext {
  const ApplicationAdminContext();

  @override
  String get id => platformContextId;
}

/// Every context of [user], Application admin first, then the academies in
/// the order of `/me`.
List<AppContext> contextsOf(CurrentUser user) => [
  if (user.superAdmin) const ApplicationAdminContext(),
  for (final m in user.memberships) AcademyContext(m),
];
