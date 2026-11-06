import 'package:drift/drift.dart';

part 'match_database.g.dart';

/// Matches last seen online, as contract JSON (offline list / header).
@DataClassName('MatchCacheRow')
class MatchesCache extends Table {
  @override
  String get tableName => 'matches_cache';
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get teamId => text()();
  TextColumn get json => text()();
  DateTimeColumn get cachedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Match roster snapshot; lets a match be scored without network.
@DataClassName('RosterCacheRow')
class RosterCache extends Table {
  @override
  String get tableName => 'roster_cache';
  TextColumn get tenantId => text()();
  TextColumn get matchId => text()();
  TextColumn get playerId => text()();
  IntColumn get position => integer()();
  TextColumn get displayName => text()();
  TextColumn get jerseyNumber => text().nullable()();
  BoolColumn get isStarter => boolean()();
  @override
  Set<Column> get primaryKey => {tenantId, matchId, playerId};
}

/// Events recorded on this device and their sync state (never deleted
/// automatically; REJECTED ones only by an explicit user discard).
@DataClassName('PendingEventRow')
class PendingEvents extends Table {
  @override
  String get tableName => 'pending_events';
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get matchId => text()();
  TextColumn get personId => text()();
  TextColumn get deviceId => text()();
  IntColumn get clientSeq => integer()();
  TextColumn get type => text()();
  TextColumn get playerId => text().nullable()();
  IntColumn get period => integer()();
  IntColumn get clockSecondsRemaining => integer()();

  /// Contract payload JSON (null for types without payload).
  TextColumn get payload => text().nullable()();

  /// ISO-8601 UTC (text keeps sub-second precision exactly).
  TextColumn get recordedAtClient => text()();
  TextColumn get status => text()();
  TextColumn get rejectReason => text().nullable()();
  IntColumn get serverSeq => integer().nullable()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<Set<Column>> get uniqueKeys => [
    {matchId, deviceId, clientSeq},
  ];
}

/// Events pulled from the server feed; max(serverSeq) per match = cursor.
@DataClassName('SyncedEventRow')
class SyncedEvents extends Table {
  @override
  String get tableName => 'synced_events';
  TextColumn get id => text()();
  TextColumn get matchId => text()();
  IntColumn get serverSeq => integer()();

  /// Contract MatchEvent JSON.
  TextColumn get json => text()();
  TextColumn get recordedByPersonId => text().nullable()();
  TextColumn get recordedByName => text().nullable()();
  TextColumn get voidedByEventId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// This installation: deviceId generated once (single row, slot 0).
@DataClassName('DeviceRow')
class Device extends Table {
  @override
  String get tableName => 'device';
  IntColumn get slot => integer()();
  TextColumn get deviceId => text()();

  /// `sub` of the user whose data this DB holds (F-07); null until bound.
  TextColumn get ownerSub => text().nullable()();
  @override
  Set<Column> get primaryKey => {slot};
}

/// Last clientSeq handed out per match (monotonic, survives discards).
@DataClassName('ClientSequenceRow')
class ClientSequences extends Table {
  @override
  String get tableName => 'client_sequences';
  TextColumn get matchId => text()();
  IntColumn get lastClientSeq => integer()();
  @override
  Set<Column> get primaryKey => {matchId};
}

@DriftDatabase(
  tables: [
    MatchesCache,
    RosterCache,
    PendingEvents,
    SyncedEvents,
    Device,
    ClientSequences,
  ],
)
class MatchDatabase extends _$MatchDatabase {
  MatchDatabase(super.connection);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // v2 (F-07): the roster cache gains tenant_id in its key and the device
    // row an owner. Caches are re-fetchable, so the roster cache is rebuilt.
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.deleteTable('roster_cache');
        await m.createTable(rosterCache);
        await m.addColumn(device, device.ownerSub);
      }
    },
    onCreate: (m) async {
      await m.createAll();
      await m.createIndex(
        Index(
          'pending_events_outbox',
          'CREATE INDEX pending_events_outbox ON pending_events (tenant_id, person_id, status, match_id, client_seq)',
        ),
      );
      await m.createIndex(
        Index(
          'synced_events_match',
          'CREATE INDEX synced_events_match ON synced_events (match_id, server_seq)',
        ),
      );
    },
  );
}
