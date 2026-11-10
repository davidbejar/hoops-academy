import '../../features/me/domain/current_user.dart';
import '../navigation/destinations.dart';
import 'app_context.dart';

export 'app_context.dart';

/// Everything the router needs to know about "who is using the app".
sealed class SessionState {
  const SessionState();

  const factory SessionState.initializing() = _Simple;
  const factory SessionState.signedOut() = _Simple.signedOut;
  const factory SessionState.loadingProfile() = _Simple.loadingProfile;
  const factory SessionState.profileError() = _Simple.profileError;
  const factory SessionState.needsTenant(CurrentUser user) = NeedsTenant;
  const factory SessionState.ready({
    required CurrentUser user,
    required TenantMembership? membership,
    bool applicationAdmin,
  }) = Ready;
}

enum _Phase { initializing, signedOut, loadingProfile, profileError }

class _Simple extends SessionState {
  const _Simple() : phase = _Phase.initializing;
  const _Simple.signedOut() : phase = _Phase.signedOut;
  const _Simple.loadingProfile() : phase = _Phase.loadingProfile;
  const _Simple.profileError() : phase = _Phase.profileError;

  final _Phase phase;
}

/// Signed in, profile loaded, several contexts (academies, Application admin)
/// and none chosen or remembered yet.
class NeedsTenant extends SessionState {
  const NeedsTenant(this.user);
  final CurrentUser user;
}

/// Signed in with a usable context: an academy ([membership]) or, when
/// [applicationAdmin], the application admin of a super admin (no academy, so
/// no tenant header). [membership] is null in the latter case and for a login
/// without any access.
class Ready extends SessionState {
  const Ready({
    required this.user,
    required this.membership,
    this.applicationAdmin = false,
  });
  final CurrentUser user;
  final TenantMembership? membership;
  final bool applicationAdmin;

  Set<TenantRole> get roles => membership?.roles ?? const {};
}

/// The session of a loaded login: the context it works in is the [selected]
/// one when it is still valid, else the only one, else the user must choose.
SessionState sessionFor(CurrentUser user, String? selected) {
  final contexts = contextsOf(user);
  AppContext? chosen;
  for (final c in contexts) {
    if (c.id == selected) chosen = c;
  }
  chosen ??= contexts.length == 1 ? contexts.single : null;
  return switch (chosen) {
    ApplicationAdminContext() => SessionState.ready(
      user: user,
      membership: null,
      applicationAdmin: true,
    ),
    AcademyContext(:final membership) => SessionState.ready(
      user: user,
      membership: membership,
    ),
    null when contexts.isEmpty => SessionState.ready(
      user: user,
      membership: null,
    ),
    null => SessionState.needsTenant(user),
  };
}

/// Routes any signed-in user may open regardless of role.
const _commonPaths = {'/profile', '/tenants'};

/// The public landing page (WP70): `/` and its alias `/welcome`.
const landingPaths = {'/', '/welcome'};

/// Where the old platform console routes (`/platform...`) live in the
/// application admin (WP99); null for any other path.
String? legacyPlatformPath(String location) {
  if (location == '/platform') return '/app-admin/academies';
  if (!location.startsWith('/platform/')) return null;
  final rest = location.substring('/platform/'.length);
  if (rest == 'requests' || rest == 'activity') return '/app-admin/$rest';
  return '/app-admin/academies/$rest';
}

/// Whether [location] belongs to the application admin.
bool isApplicationAdminPath(String location) =>
    location == '/app-admin' || location.startsWith('/app-admin/');

/// The auth/tenant/role guard as a pure function: returns the path to go to,
/// or null to stay on [location].
String? redirectFor(SessionState session, String location) {
  String? go(String target) => location == target ? null : target;

  switch (session) {
    case _Simple(:final phase):
      // While auth initialises the landing routes stay put: the root route
      // shows the splash until the status is known (no flash for a signed-in
      // user), and a cold start at `/` can still become the landing.
      if (landingPaths.contains(location) &&
          (phase == _Phase.initializing || phase == _Phase.signedOut)) {
        return null;
      }
      return switch (phase) {
        _Phase.initializing ||
        _Phase.loadingProfile ||
        _Phase.profileError => go('/splash'),
        _Phase.signedOut => go('/login'),
      };
    case NeedsTenant():
      return location == '/profile' ? null : go('/tenants');
    case Ready(:final user, :final roles, :final applicationAdmin):
      if (_commonPaths.contains(location)) return null;
      final destinations = destinationsFor(
        roles: roles,
        applicationAdmin: applicationAdmin,
      );
      if (destinations.isEmpty) return go('/no-access');
      // The links of the old platform console lead to the same screens of
      // the application admin (a super admin only).
      final legacy = legacyPlatformPath(location);
      if (legacy != null && user.superAdmin) return legacy;
      final allowed = destinations.map((d) => d.path).toSet();
      // A destination owns its sub-routes (`/teams/<id>`, `/admin/members`).
      if (allowed.any((p) => location == p || location.startsWith('$p/'))) {
        return null;
      }
      return destinations.first.path;
  }
}
