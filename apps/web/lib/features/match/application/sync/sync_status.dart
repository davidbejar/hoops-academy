/// Why the last sync attempt failed.
enum SyncErrorKind { network, unauthorized, server }

/// What the "N unsynced" banner and the event log show.
class SyncStatus {
  const SyncStatus({
    this.pendingCount = 0,
    this.rejectedCount = 0,
    this.syncing = false,
    this.lastError,
    this.pausedForAuth = false,
    this.nextRetryAt,
  });

  /// Events of this person not answered by the server yet (all matches).
  final int pendingCount;

  /// REJECTED events still in the queue (shown until discarded).
  final int rejectedCount;
  final bool syncing;
  final SyncErrorKind? lastError;

  /// 401 after a failed refresh: nothing is sent until the user signs in.
  final bool pausedForAuth;
  final DateTime? nextRetryAt;

  SyncStatus copyWith({
    int? pendingCount,
    int? rejectedCount,
    bool? syncing,
    SyncErrorKind? Function()? lastError,
    bool? pausedForAuth,
    DateTime? Function()? nextRetryAt,
  }) => SyncStatus(
    pendingCount: pendingCount ?? this.pendingCount,
    rejectedCount: rejectedCount ?? this.rejectedCount,
    syncing: syncing ?? this.syncing,
    lastError: lastError != null ? lastError() : this.lastError,
    pausedForAuth: pausedForAuth ?? this.pausedForAuth,
    nextRetryAt: nextRetryAt != null ? nextRetryAt() : this.nextRetryAt,
  );
}
