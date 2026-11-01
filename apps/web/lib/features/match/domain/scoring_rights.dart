import '../../../core/session/capabilities.dart';

/// What the caller may do in one match (authz matrix + ADR-0014 §4). UI
/// affordances only; the server decides per event (NOT_AUTHORIZED).
class ScoringRights {
  const ScoringRights({required this.staff, required this.linkedPlayerIds});

  factory ScoringRights.of(Capabilities caps, {required String teamId}) => ScoringRights(
    staff: caps.canRunMatch(teamId),
    linkedPlayerIds: {
      for (final p in caps.linkedPlayerIds)
        if (caps.isLinkedTo(p)) p,
    },
  );

  static const none = ScoringRights(staff: false, linkedPlayerIds: {});

  /// ADMIN / team staff: everything (any event, clock, periods, roster).
  final bool staff;
  final Set<String> linkedPlayerIds;

  bool get canRunMatch => staff;
  bool get canScore => staff || linkedPlayerIds.isNotEmpty;

  /// Parent-restricted mode: linked players only, no clock/period/opponent.
  bool get parentMode => !staff && linkedPlayerIds.isNotEmpty;

  bool canRecordFor(String playerId) => staff || linkedPlayerIds.contains(playerId);

  /// Staff may VOID anything; a parent only events they recorded.
  bool canVoid({required bool recordedByMe}) => staff || (canScore && recordedByMe);

  /// Box score lines shown from the local projection (like `GET box-score`:
  /// staff all, PARENT linked; PLAYER self is unknown client-side -> totals).
  bool canSeeLine(String playerId) => staff || linkedPlayerIds.contains(playerId);
}
