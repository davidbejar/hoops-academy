import '../../features/me/domain/current_user.dart';
import '../navigation/destinations.dart';

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

/// Signed in, profile loaded, several memberships and none selected yet.
class NeedsTenant extends SessionState {
  const NeedsTenant(this.user);
  final CurrentUser user;
}

/// Signed in with a usable context. [membership] is null only for a
/// `super_admin` without memberships (platform area) or a user with no access.
class Ready extends SessionState {
  const Ready({required this.user, required this.membership});
  final CurrentUser user;
  final TenantMembership? membership;

  Set<TenantRole> get roles => membership?.roles ?? const {};
}

/// Routes any signed-in user may open regardless of role.
const _commonPaths = {'/profile', '/tenants'};

/// The auth/tenant/role guard as a pure function: returns the path to go to,
/// or null to stay on [location].
String? redirectFor(SessionState session, String location) {
  String? go(String target) => location == target ? null : target;

  switch (session) {
    case _Simple(:final phase):
      return switch (phase) {
        _Phase.initializing ||
        _Phase.loadingProfile ||
        _Phase.profileError => go('/splash'),
        _Phase.signedOut => go('/login'),
      };
    case NeedsTenant():
      return location == '/profile' ? null : go('/tenants');
    case Ready(:final user, :final roles):
      if (_commonPaths.contains(location)) return null;
      final destinations = destinationsFor(
        roles: roles,
        superAdmin: user.superAdmin,
      );
      if (destinations.isEmpty) return go('/no-access');
      final allowed = destinations.map((d) => d.path).toSet();
      // A destination owns its sub-routes (`/teams/<id>`, `/admin/members`).
      if (allowed.any((p) => location == p || location.startsWith('$p/'))) {
        return null;
      }
      return destinations.first.path;
  }
}
