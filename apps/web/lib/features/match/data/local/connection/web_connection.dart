import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Picks a storage that needs neither a SharedWorker nor cross-origin
/// isolation (COOP/COEP would break the Keycloak iframes, ADR-0004):
/// `opfsLocks` when the page happens to be isolated, else IndexedDB in the
/// page (`unsafeIndexedDb`), else in-memory (data lost on reload; reported
/// through [onStorage] so the UI can warn). Assets: `web/sqlite3.wasm` and
/// `web/drift_worker.js` (see apps/web/README.md "Offline storage").
DatabaseConnection openMatchConnection({
  void Function(String storage)? onStorage,
}) => DatabaseConnection.delayed(
  Future(() async {
    final probe = await WasmDatabase.probe(
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
      databaseName: 'hoops_match',
    );
    const preference = [
      WasmStorageImplementation.opfsLocks,
      WasmStorageImplementation.unsafeIndexedDb,
    ];
    final chosen = preference.firstWhere(
      probe.availableStorages.contains,
      orElse: () => WasmStorageImplementation.inMemory,
    );
    onStorage?.call(chosen.name);
    return probe.open(chosen, 'hoops_match');
  }),
);
