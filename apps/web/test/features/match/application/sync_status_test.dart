import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/application/sync/sync_status.dart';

/// The banner's state (WP88: pinned for the Dart mutation run).
void main() {
  test('starts with nothing pending, rejected, running or failed', () {
    const status = SyncStatus();
    expect(status.pendingCount, 0);
    expect(status.rejectedCount, 0);
    expect(status.syncing, isFalse);
    expect(status.lastError, isNull);
    expect(status.pausedForAuth, isFalse);
    expect(status.nextRetryAt, isNull);
  });

  test('copyWith keeps what it is not given and can clear the error', () {
    final retry = DateTime.utc(2026, 11, 7, 10);
    final failed = const SyncStatus().copyWith(
      pendingCount: 3,
      rejectedCount: 1,
      syncing: true,
      lastError: () => SyncErrorKind.network,
      pausedForAuth: true,
      nextRetryAt: () => retry,
    );
    final kept = failed.copyWith();
    expect(kept.pendingCount, 3);
    expect(kept.rejectedCount, 1);
    expect(kept.syncing, isTrue);
    expect(kept.lastError, SyncErrorKind.network);
    expect(kept.pausedForAuth, isTrue);
    expect(kept.nextRetryAt, retry);

    final cleared = failed.copyWith(
      lastError: () => null,
      nextRetryAt: () => null,
    );
    expect(cleared.lastError, isNull);
    expect(cleared.nextRetryAt, isNull);
    expect(cleared.pendingCount, 3);
  });
}
