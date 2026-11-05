import 'match_event.dart';

/// Mirror of game-service `EventVisibility` (ADR-0028): the events of a match
/// a caller who sees only [visiblePlayers] reads in the feed. `null` = sees
/// every player (ADMIN, team staff). Player events (stats, substitutions, a
/// note about a player) follow their player; team-level events are visible to
/// everyone; a VOID follows its target (an unknown target names no player).
/// The app never filters what the server sends; the dev mock API and the test
/// fakes use this to behave like the server.
List<T> visibleFeed<T>(List<T> stored, MatchEvent Function(T) eventOf, {required Set<String>? visiblePlayers}) {
  if (visiblePlayers == null) return stored;
  final byId = {for (final s in stored) eventOf(s).id: eventOf(s)};
  bool visible(MatchEvent event) {
    final followed = <String>{};
    var current = event;
    while (current is VoidEvent && followed.add(current.id)) {
      final target = byId[current.target];
      if (target == null) return true;
      current = target;
    }
    final player = current.playerId;
    return player == null || visiblePlayers.contains(player);
  }

  return [for (final s in stored) if (visible(eventOf(s))) s];
}
