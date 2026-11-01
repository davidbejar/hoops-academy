// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_database.dart';

// ignore_for_file: type=lint
class $MatchesCacheTable extends MatchesCache
    with TableInfo<$MatchesCacheTable, MatchCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, tenantId, teamId, json, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'matches_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatchCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MatchCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatchCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $MatchesCacheTable createAlias(String alias) {
    return $MatchesCacheTable(attachedDatabase, alias);
  }
}

class MatchCacheRow extends DataClass implements Insertable<MatchCacheRow> {
  final String id;
  final String tenantId;
  final String teamId;
  final String json;
  final DateTime cachedAt;
  const MatchCacheRow({
    required this.id,
    required this.tenantId,
    required this.teamId,
    required this.json,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['team_id'] = Variable<String>(teamId);
    map['json'] = Variable<String>(json);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  MatchesCacheCompanion toCompanion(bool nullToAbsent) {
    return MatchesCacheCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      teamId: Value(teamId),
      json: Value(json),
      cachedAt: Value(cachedAt),
    );
  }

  factory MatchCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatchCacheRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      teamId: serializer.fromJson<String>(json['teamId']),
      json: serializer.fromJson<String>(json['json']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'teamId': serializer.toJson<String>(teamId),
      'json': serializer.toJson<String>(json),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  MatchCacheRow copyWith({
    String? id,
    String? tenantId,
    String? teamId,
    String? json,
    DateTime? cachedAt,
  }) => MatchCacheRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    teamId: teamId ?? this.teamId,
    json: json ?? this.json,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  MatchCacheRow copyWithCompanion(MatchesCacheCompanion data) {
    return MatchCacheRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      json: data.json.present ? data.json.value : this.json,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchCacheRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('teamId: $teamId, ')
          ..write('json: $json, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tenantId, teamId, json, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchCacheRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.teamId == this.teamId &&
          other.json == this.json &&
          other.cachedAt == this.cachedAt);
}

class MatchesCacheCompanion extends UpdateCompanion<MatchCacheRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> teamId;
  final Value<String> json;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const MatchesCacheCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.teamId = const Value.absent(),
    this.json = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchesCacheCompanion.insert({
    required String id,
    required String tenantId,
    required String teamId,
    required String json,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       teamId = Value(teamId),
       json = Value(json),
       cachedAt = Value(cachedAt);
  static Insertable<MatchCacheRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? teamId,
    Expression<String>? json,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (teamId != null) 'team_id': teamId,
      if (json != null) 'json': json,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchesCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? teamId,
    Value<String>? json,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return MatchesCacheCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      teamId: teamId ?? this.teamId,
      json: json ?? this.json,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchesCacheCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('teamId: $teamId, ')
          ..write('json: $json, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RosterCacheTable extends RosterCache
    with TableInfo<$RosterCacheTable, RosterCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RosterCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jerseyNumberMeta = const VerificationMeta(
    'jerseyNumber',
  );
  @override
  late final GeneratedColumn<String> jerseyNumber = GeneratedColumn<String>(
    'jersey_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isStarterMeta = const VerificationMeta(
    'isStarter',
  );
  @override
  late final GeneratedColumn<bool> isStarter = GeneratedColumn<bool>(
    'is_starter',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_starter" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    matchId,
    playerId,
    position,
    displayName,
    jerseyNumber,
    isStarter,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'roster_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<RosterCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('jersey_number')) {
      context.handle(
        _jerseyNumberMeta,
        jerseyNumber.isAcceptableOrUnknown(
          data['jersey_number']!,
          _jerseyNumberMeta,
        ),
      );
    }
    if (data.containsKey('is_starter')) {
      context.handle(
        _isStarterMeta,
        isStarter.isAcceptableOrUnknown(data['is_starter']!, _isStarterMeta),
      );
    } else if (isInserting) {
      context.missing(_isStarterMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matchId, playerId};
  @override
  RosterCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RosterCacheRow(
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      jerseyNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jersey_number'],
      ),
      isStarter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_starter'],
      )!,
    );
  }

  @override
  $RosterCacheTable createAlias(String alias) {
    return $RosterCacheTable(attachedDatabase, alias);
  }
}

class RosterCacheRow extends DataClass implements Insertable<RosterCacheRow> {
  final String matchId;
  final String playerId;
  final int position;
  final String displayName;
  final String? jerseyNumber;
  final bool isStarter;
  const RosterCacheRow({
    required this.matchId,
    required this.playerId,
    required this.position,
    required this.displayName,
    this.jerseyNumber,
    required this.isStarter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['match_id'] = Variable<String>(matchId);
    map['player_id'] = Variable<String>(playerId);
    map['position'] = Variable<int>(position);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || jerseyNumber != null) {
      map['jersey_number'] = Variable<String>(jerseyNumber);
    }
    map['is_starter'] = Variable<bool>(isStarter);
    return map;
  }

  RosterCacheCompanion toCompanion(bool nullToAbsent) {
    return RosterCacheCompanion(
      matchId: Value(matchId),
      playerId: Value(playerId),
      position: Value(position),
      displayName: Value(displayName),
      jerseyNumber: jerseyNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(jerseyNumber),
      isStarter: Value(isStarter),
    );
  }

  factory RosterCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RosterCacheRow(
      matchId: serializer.fromJson<String>(json['matchId']),
      playerId: serializer.fromJson<String>(json['playerId']),
      position: serializer.fromJson<int>(json['position']),
      displayName: serializer.fromJson<String>(json['displayName']),
      jerseyNumber: serializer.fromJson<String?>(json['jerseyNumber']),
      isStarter: serializer.fromJson<bool>(json['isStarter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matchId': serializer.toJson<String>(matchId),
      'playerId': serializer.toJson<String>(playerId),
      'position': serializer.toJson<int>(position),
      'displayName': serializer.toJson<String>(displayName),
      'jerseyNumber': serializer.toJson<String?>(jerseyNumber),
      'isStarter': serializer.toJson<bool>(isStarter),
    };
  }

  RosterCacheRow copyWith({
    String? matchId,
    String? playerId,
    int? position,
    String? displayName,
    Value<String?> jerseyNumber = const Value.absent(),
    bool? isStarter,
  }) => RosterCacheRow(
    matchId: matchId ?? this.matchId,
    playerId: playerId ?? this.playerId,
    position: position ?? this.position,
    displayName: displayName ?? this.displayName,
    jerseyNumber: jerseyNumber.present ? jerseyNumber.value : this.jerseyNumber,
    isStarter: isStarter ?? this.isStarter,
  );
  RosterCacheRow copyWithCompanion(RosterCacheCompanion data) {
    return RosterCacheRow(
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      position: data.position.present ? data.position.value : this.position,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      jerseyNumber: data.jerseyNumber.present
          ? data.jerseyNumber.value
          : this.jerseyNumber,
      isStarter: data.isStarter.present ? data.isStarter.value : this.isStarter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RosterCacheRow(')
          ..write('matchId: $matchId, ')
          ..write('playerId: $playerId, ')
          ..write('position: $position, ')
          ..write('displayName: $displayName, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('isStarter: $isStarter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    matchId,
    playerId,
    position,
    displayName,
    jerseyNumber,
    isStarter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RosterCacheRow &&
          other.matchId == this.matchId &&
          other.playerId == this.playerId &&
          other.position == this.position &&
          other.displayName == this.displayName &&
          other.jerseyNumber == this.jerseyNumber &&
          other.isStarter == this.isStarter);
}

class RosterCacheCompanion extends UpdateCompanion<RosterCacheRow> {
  final Value<String> matchId;
  final Value<String> playerId;
  final Value<int> position;
  final Value<String> displayName;
  final Value<String?> jerseyNumber;
  final Value<bool> isStarter;
  final Value<int> rowid;
  const RosterCacheCompanion({
    this.matchId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.position = const Value.absent(),
    this.displayName = const Value.absent(),
    this.jerseyNumber = const Value.absent(),
    this.isStarter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RosterCacheCompanion.insert({
    required String matchId,
    required String playerId,
    required int position,
    required String displayName,
    this.jerseyNumber = const Value.absent(),
    required bool isStarter,
    this.rowid = const Value.absent(),
  }) : matchId = Value(matchId),
       playerId = Value(playerId),
       position = Value(position),
       displayName = Value(displayName),
       isStarter = Value(isStarter);
  static Insertable<RosterCacheRow> custom({
    Expression<String>? matchId,
    Expression<String>? playerId,
    Expression<int>? position,
    Expression<String>? displayName,
    Expression<String>? jerseyNumber,
    Expression<bool>? isStarter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (matchId != null) 'match_id': matchId,
      if (playerId != null) 'player_id': playerId,
      if (position != null) 'position': position,
      if (displayName != null) 'display_name': displayName,
      if (jerseyNumber != null) 'jersey_number': jerseyNumber,
      if (isStarter != null) 'is_starter': isStarter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RosterCacheCompanion copyWith({
    Value<String>? matchId,
    Value<String>? playerId,
    Value<int>? position,
    Value<String>? displayName,
    Value<String?>? jerseyNumber,
    Value<bool>? isStarter,
    Value<int>? rowid,
  }) {
    return RosterCacheCompanion(
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      position: position ?? this.position,
      displayName: displayName ?? this.displayName,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      isStarter: isStarter ?? this.isStarter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (jerseyNumber.present) {
      map['jersey_number'] = Variable<String>(jerseyNumber.value);
    }
    if (isStarter.present) {
      map['is_starter'] = Variable<bool>(isStarter.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RosterCacheCompanion(')
          ..write('matchId: $matchId, ')
          ..write('playerId: $playerId, ')
          ..write('position: $position, ')
          ..write('displayName: $displayName, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('isStarter: $isStarter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingEventsTable extends PendingEvents
    with TableInfo<$PendingEventsTable, PendingEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientSeqMeta = const VerificationMeta(
    'clientSeq',
  );
  @override
  late final GeneratedColumn<int> clientSeq = GeneratedColumn<int>(
    'client_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<int> period = GeneratedColumn<int>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clockSecondsRemainingMeta =
      const VerificationMeta('clockSecondsRemaining');
  @override
  late final GeneratedColumn<int> clockSecondsRemaining = GeneratedColumn<int>(
    'clock_seconds_remaining',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtClientMeta = const VerificationMeta(
    'recordedAtClient',
  );
  @override
  late final GeneratedColumn<String> recordedAtClient = GeneratedColumn<String>(
    'recorded_at_client',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rejectReasonMeta = const VerificationMeta(
    'rejectReason',
  );
  @override
  late final GeneratedColumn<String> rejectReason = GeneratedColumn<String>(
    'reject_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    matchId,
    personId,
    deviceId,
    clientSeq,
    type,
    playerId,
    period,
    clockSecondsRemaining,
    payload,
    recordedAtClient,
    status,
    rejectReason,
    serverSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('client_seq')) {
      context.handle(
        _clientSeqMeta,
        clientSeq.isAcceptableOrUnknown(data['client_seq']!, _clientSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_clientSeqMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('clock_seconds_remaining')) {
      context.handle(
        _clockSecondsRemainingMeta,
        clockSecondsRemaining.isAcceptableOrUnknown(
          data['clock_seconds_remaining']!,
          _clockSecondsRemainingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clockSecondsRemainingMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('recorded_at_client')) {
      context.handle(
        _recordedAtClientMeta,
        recordedAtClient.isAcceptableOrUnknown(
          data['recorded_at_client']!,
          _recordedAtClientMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedAtClientMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('reject_reason')) {
      context.handle(
        _rejectReasonMeta,
        rejectReason.isAcceptableOrUnknown(
          data['reject_reason']!,
          _rejectReasonMeta,
        ),
      );
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {matchId, deviceId, clientSeq},
  ];
  @override
  PendingEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      clientSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_seq'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      ),
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period'],
      )!,
      clockSecondsRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clock_seconds_remaining'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      recordedAtClient: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_at_client'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      rejectReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reject_reason'],
      ),
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      ),
    );
  }

  @override
  $PendingEventsTable createAlias(String alias) {
    return $PendingEventsTable(attachedDatabase, alias);
  }
}

class PendingEventRow extends DataClass implements Insertable<PendingEventRow> {
  final String id;
  final String tenantId;
  final String matchId;
  final String personId;
  final String deviceId;
  final int clientSeq;
  final String type;
  final String? playerId;
  final int period;
  final int clockSecondsRemaining;

  /// Contract payload JSON (null for types without payload).
  final String? payload;

  /// ISO-8601 UTC (text keeps sub-second precision exactly).
  final String recordedAtClient;
  final String status;
  final String? rejectReason;
  final int? serverSeq;
  const PendingEventRow({
    required this.id,
    required this.tenantId,
    required this.matchId,
    required this.personId,
    required this.deviceId,
    required this.clientSeq,
    required this.type,
    this.playerId,
    required this.period,
    required this.clockSecondsRemaining,
    this.payload,
    required this.recordedAtClient,
    required this.status,
    this.rejectReason,
    this.serverSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['match_id'] = Variable<String>(matchId);
    map['person_id'] = Variable<String>(personId);
    map['device_id'] = Variable<String>(deviceId);
    map['client_seq'] = Variable<int>(clientSeq);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || playerId != null) {
      map['player_id'] = Variable<String>(playerId);
    }
    map['period'] = Variable<int>(period);
    map['clock_seconds_remaining'] = Variable<int>(clockSecondsRemaining);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['recorded_at_client'] = Variable<String>(recordedAtClient);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || rejectReason != null) {
      map['reject_reason'] = Variable<String>(rejectReason);
    }
    if (!nullToAbsent || serverSeq != null) {
      map['server_seq'] = Variable<int>(serverSeq);
    }
    return map;
  }

  PendingEventsCompanion toCompanion(bool nullToAbsent) {
    return PendingEventsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      matchId: Value(matchId),
      personId: Value(personId),
      deviceId: Value(deviceId),
      clientSeq: Value(clientSeq),
      type: Value(type),
      playerId: playerId == null && nullToAbsent
          ? const Value.absent()
          : Value(playerId),
      period: Value(period),
      clockSecondsRemaining: Value(clockSecondsRemaining),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      recordedAtClient: Value(recordedAtClient),
      status: Value(status),
      rejectReason: rejectReason == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectReason),
      serverSeq: serverSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSeq),
    );
  }

  factory PendingEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingEventRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      matchId: serializer.fromJson<String>(json['matchId']),
      personId: serializer.fromJson<String>(json['personId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      clientSeq: serializer.fromJson<int>(json['clientSeq']),
      type: serializer.fromJson<String>(json['type']),
      playerId: serializer.fromJson<String?>(json['playerId']),
      period: serializer.fromJson<int>(json['period']),
      clockSecondsRemaining: serializer.fromJson<int>(
        json['clockSecondsRemaining'],
      ),
      payload: serializer.fromJson<String?>(json['payload']),
      recordedAtClient: serializer.fromJson<String>(json['recordedAtClient']),
      status: serializer.fromJson<String>(json['status']),
      rejectReason: serializer.fromJson<String?>(json['rejectReason']),
      serverSeq: serializer.fromJson<int?>(json['serverSeq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'matchId': serializer.toJson<String>(matchId),
      'personId': serializer.toJson<String>(personId),
      'deviceId': serializer.toJson<String>(deviceId),
      'clientSeq': serializer.toJson<int>(clientSeq),
      'type': serializer.toJson<String>(type),
      'playerId': serializer.toJson<String?>(playerId),
      'period': serializer.toJson<int>(period),
      'clockSecondsRemaining': serializer.toJson<int>(clockSecondsRemaining),
      'payload': serializer.toJson<String?>(payload),
      'recordedAtClient': serializer.toJson<String>(recordedAtClient),
      'status': serializer.toJson<String>(status),
      'rejectReason': serializer.toJson<String?>(rejectReason),
      'serverSeq': serializer.toJson<int?>(serverSeq),
    };
  }

  PendingEventRow copyWith({
    String? id,
    String? tenantId,
    String? matchId,
    String? personId,
    String? deviceId,
    int? clientSeq,
    String? type,
    Value<String?> playerId = const Value.absent(),
    int? period,
    int? clockSecondsRemaining,
    Value<String?> payload = const Value.absent(),
    String? recordedAtClient,
    String? status,
    Value<String?> rejectReason = const Value.absent(),
    Value<int?> serverSeq = const Value.absent(),
  }) => PendingEventRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    matchId: matchId ?? this.matchId,
    personId: personId ?? this.personId,
    deviceId: deviceId ?? this.deviceId,
    clientSeq: clientSeq ?? this.clientSeq,
    type: type ?? this.type,
    playerId: playerId.present ? playerId.value : this.playerId,
    period: period ?? this.period,
    clockSecondsRemaining: clockSecondsRemaining ?? this.clockSecondsRemaining,
    payload: payload.present ? payload.value : this.payload,
    recordedAtClient: recordedAtClient ?? this.recordedAtClient,
    status: status ?? this.status,
    rejectReason: rejectReason.present ? rejectReason.value : this.rejectReason,
    serverSeq: serverSeq.present ? serverSeq.value : this.serverSeq,
  );
  PendingEventRow copyWithCompanion(PendingEventsCompanion data) {
    return PendingEventRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      personId: data.personId.present ? data.personId.value : this.personId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      clientSeq: data.clientSeq.present ? data.clientSeq.value : this.clientSeq,
      type: data.type.present ? data.type.value : this.type,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      period: data.period.present ? data.period.value : this.period,
      clockSecondsRemaining: data.clockSecondsRemaining.present
          ? data.clockSecondsRemaining.value
          : this.clockSecondsRemaining,
      payload: data.payload.present ? data.payload.value : this.payload,
      recordedAtClient: data.recordedAtClient.present
          ? data.recordedAtClient.value
          : this.recordedAtClient,
      status: data.status.present ? data.status.value : this.status,
      rejectReason: data.rejectReason.present
          ? data.rejectReason.value
          : this.rejectReason,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingEventRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('matchId: $matchId, ')
          ..write('personId: $personId, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientSeq: $clientSeq, ')
          ..write('type: $type, ')
          ..write('playerId: $playerId, ')
          ..write('period: $period, ')
          ..write('clockSecondsRemaining: $clockSecondsRemaining, ')
          ..write('payload: $payload, ')
          ..write('recordedAtClient: $recordedAtClient, ')
          ..write('status: $status, ')
          ..write('rejectReason: $rejectReason, ')
          ..write('serverSeq: $serverSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    matchId,
    personId,
    deviceId,
    clientSeq,
    type,
    playerId,
    period,
    clockSecondsRemaining,
    payload,
    recordedAtClient,
    status,
    rejectReason,
    serverSeq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingEventRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.matchId == this.matchId &&
          other.personId == this.personId &&
          other.deviceId == this.deviceId &&
          other.clientSeq == this.clientSeq &&
          other.type == this.type &&
          other.playerId == this.playerId &&
          other.period == this.period &&
          other.clockSecondsRemaining == this.clockSecondsRemaining &&
          other.payload == this.payload &&
          other.recordedAtClient == this.recordedAtClient &&
          other.status == this.status &&
          other.rejectReason == this.rejectReason &&
          other.serverSeq == this.serverSeq);
}

class PendingEventsCompanion extends UpdateCompanion<PendingEventRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> matchId;
  final Value<String> personId;
  final Value<String> deviceId;
  final Value<int> clientSeq;
  final Value<String> type;
  final Value<String?> playerId;
  final Value<int> period;
  final Value<int> clockSecondsRemaining;
  final Value<String?> payload;
  final Value<String> recordedAtClient;
  final Value<String> status;
  final Value<String?> rejectReason;
  final Value<int?> serverSeq;
  final Value<int> rowid;
  const PendingEventsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.matchId = const Value.absent(),
    this.personId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.clientSeq = const Value.absent(),
    this.type = const Value.absent(),
    this.playerId = const Value.absent(),
    this.period = const Value.absent(),
    this.clockSecondsRemaining = const Value.absent(),
    this.payload = const Value.absent(),
    this.recordedAtClient = const Value.absent(),
    this.status = const Value.absent(),
    this.rejectReason = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingEventsCompanion.insert({
    required String id,
    required String tenantId,
    required String matchId,
    required String personId,
    required String deviceId,
    required int clientSeq,
    required String type,
    this.playerId = const Value.absent(),
    required int period,
    required int clockSecondsRemaining,
    this.payload = const Value.absent(),
    required String recordedAtClient,
    required String status,
    this.rejectReason = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       matchId = Value(matchId),
       personId = Value(personId),
       deviceId = Value(deviceId),
       clientSeq = Value(clientSeq),
       type = Value(type),
       period = Value(period),
       clockSecondsRemaining = Value(clockSecondsRemaining),
       recordedAtClient = Value(recordedAtClient),
       status = Value(status);
  static Insertable<PendingEventRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? matchId,
    Expression<String>? personId,
    Expression<String>? deviceId,
    Expression<int>? clientSeq,
    Expression<String>? type,
    Expression<String>? playerId,
    Expression<int>? period,
    Expression<int>? clockSecondsRemaining,
    Expression<String>? payload,
    Expression<String>? recordedAtClient,
    Expression<String>? status,
    Expression<String>? rejectReason,
    Expression<int>? serverSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (matchId != null) 'match_id': matchId,
      if (personId != null) 'person_id': personId,
      if (deviceId != null) 'device_id': deviceId,
      if (clientSeq != null) 'client_seq': clientSeq,
      if (type != null) 'type': type,
      if (playerId != null) 'player_id': playerId,
      if (period != null) 'period': period,
      if (clockSecondsRemaining != null)
        'clock_seconds_remaining': clockSecondsRemaining,
      if (payload != null) 'payload': payload,
      if (recordedAtClient != null) 'recorded_at_client': recordedAtClient,
      if (status != null) 'status': status,
      if (rejectReason != null) 'reject_reason': rejectReason,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? matchId,
    Value<String>? personId,
    Value<String>? deviceId,
    Value<int>? clientSeq,
    Value<String>? type,
    Value<String?>? playerId,
    Value<int>? period,
    Value<int>? clockSecondsRemaining,
    Value<String?>? payload,
    Value<String>? recordedAtClient,
    Value<String>? status,
    Value<String?>? rejectReason,
    Value<int?>? serverSeq,
    Value<int>? rowid,
  }) {
    return PendingEventsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      matchId: matchId ?? this.matchId,
      personId: personId ?? this.personId,
      deviceId: deviceId ?? this.deviceId,
      clientSeq: clientSeq ?? this.clientSeq,
      type: type ?? this.type,
      playerId: playerId ?? this.playerId,
      period: period ?? this.period,
      clockSecondsRemaining:
          clockSecondsRemaining ?? this.clockSecondsRemaining,
      payload: payload ?? this.payload,
      recordedAtClient: recordedAtClient ?? this.recordedAtClient,
      status: status ?? this.status,
      rejectReason: rejectReason ?? this.rejectReason,
      serverSeq: serverSeq ?? this.serverSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (clientSeq.present) {
      map['client_seq'] = Variable<int>(clientSeq.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (period.present) {
      map['period'] = Variable<int>(period.value);
    }
    if (clockSecondsRemaining.present) {
      map['clock_seconds_remaining'] = Variable<int>(
        clockSecondsRemaining.value,
      );
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (recordedAtClient.present) {
      map['recorded_at_client'] = Variable<String>(recordedAtClient.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rejectReason.present) {
      map['reject_reason'] = Variable<String>(rejectReason.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingEventsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('matchId: $matchId, ')
          ..write('personId: $personId, ')
          ..write('deviceId: $deviceId, ')
          ..write('clientSeq: $clientSeq, ')
          ..write('type: $type, ')
          ..write('playerId: $playerId, ')
          ..write('period: $period, ')
          ..write('clockSecondsRemaining: $clockSecondsRemaining, ')
          ..write('payload: $payload, ')
          ..write('recordedAtClient: $recordedAtClient, ')
          ..write('status: $status, ')
          ..write('rejectReason: $rejectReason, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncedEventsTable extends SyncedEvents
    with TableInfo<$SyncedEventsTable, SyncedEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverSeqMeta = const VerificationMeta(
    'serverSeq',
  );
  @override
  late final GeneratedColumn<int> serverSeq = GeneratedColumn<int>(
    'server_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedByPersonIdMeta =
      const VerificationMeta('recordedByPersonId');
  @override
  late final GeneratedColumn<String> recordedByPersonId =
      GeneratedColumn<String>(
        'recorded_by_person_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recordedByNameMeta = const VerificationMeta(
    'recordedByName',
  );
  @override
  late final GeneratedColumn<String> recordedByName = GeneratedColumn<String>(
    'recorded_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voidedByEventIdMeta = const VerificationMeta(
    'voidedByEventId',
  );
  @override
  late final GeneratedColumn<String> voidedByEventId = GeneratedColumn<String>(
    'voided_by_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    matchId,
    serverSeq,
    json,
    recordedByPersonId,
    recordedByName,
    voidedByEventId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synced_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncedEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('server_seq')) {
      context.handle(
        _serverSeqMeta,
        serverSeq.isAcceptableOrUnknown(data['server_seq']!, _serverSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_serverSeqMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('recorded_by_person_id')) {
      context.handle(
        _recordedByPersonIdMeta,
        recordedByPersonId.isAcceptableOrUnknown(
          data['recorded_by_person_id']!,
          _recordedByPersonIdMeta,
        ),
      );
    }
    if (data.containsKey('recorded_by_name')) {
      context.handle(
        _recordedByNameMeta,
        recordedByName.isAcceptableOrUnknown(
          data['recorded_by_name']!,
          _recordedByNameMeta,
        ),
      );
    }
    if (data.containsKey('voided_by_event_id')) {
      context.handle(
        _voidedByEventIdMeta,
        voidedByEventId.isAcceptableOrUnknown(
          data['voided_by_event_id']!,
          _voidedByEventIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncedEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      serverSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_seq'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      recordedByPersonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_person_id'],
      ),
      recordedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_name'],
      ),
      voidedByEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voided_by_event_id'],
      ),
    );
  }

  @override
  $SyncedEventsTable createAlias(String alias) {
    return $SyncedEventsTable(attachedDatabase, alias);
  }
}

class SyncedEventRow extends DataClass implements Insertable<SyncedEventRow> {
  final String id;
  final String matchId;
  final int serverSeq;

  /// Contract MatchEvent JSON.
  final String json;
  final String? recordedByPersonId;
  final String? recordedByName;
  final String? voidedByEventId;
  const SyncedEventRow({
    required this.id,
    required this.matchId,
    required this.serverSeq,
    required this.json,
    this.recordedByPersonId,
    this.recordedByName,
    this.voidedByEventId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['match_id'] = Variable<String>(matchId);
    map['server_seq'] = Variable<int>(serverSeq);
    map['json'] = Variable<String>(json);
    if (!nullToAbsent || recordedByPersonId != null) {
      map['recorded_by_person_id'] = Variable<String>(recordedByPersonId);
    }
    if (!nullToAbsent || recordedByName != null) {
      map['recorded_by_name'] = Variable<String>(recordedByName);
    }
    if (!nullToAbsent || voidedByEventId != null) {
      map['voided_by_event_id'] = Variable<String>(voidedByEventId);
    }
    return map;
  }

  SyncedEventsCompanion toCompanion(bool nullToAbsent) {
    return SyncedEventsCompanion(
      id: Value(id),
      matchId: Value(matchId),
      serverSeq: Value(serverSeq),
      json: Value(json),
      recordedByPersonId: recordedByPersonId == null && nullToAbsent
          ? const Value.absent()
          : Value(recordedByPersonId),
      recordedByName: recordedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(recordedByName),
      voidedByEventId: voidedByEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedByEventId),
    );
  }

  factory SyncedEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedEventRow(
      id: serializer.fromJson<String>(json['id']),
      matchId: serializer.fromJson<String>(json['matchId']),
      serverSeq: serializer.fromJson<int>(json['serverSeq']),
      json: serializer.fromJson<String>(json['json']),
      recordedByPersonId: serializer.fromJson<String?>(
        json['recordedByPersonId'],
      ),
      recordedByName: serializer.fromJson<String?>(json['recordedByName']),
      voidedByEventId: serializer.fromJson<String?>(json['voidedByEventId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'matchId': serializer.toJson<String>(matchId),
      'serverSeq': serializer.toJson<int>(serverSeq),
      'json': serializer.toJson<String>(json),
      'recordedByPersonId': serializer.toJson<String?>(recordedByPersonId),
      'recordedByName': serializer.toJson<String?>(recordedByName),
      'voidedByEventId': serializer.toJson<String?>(voidedByEventId),
    };
  }

  SyncedEventRow copyWith({
    String? id,
    String? matchId,
    int? serverSeq,
    String? json,
    Value<String?> recordedByPersonId = const Value.absent(),
    Value<String?> recordedByName = const Value.absent(),
    Value<String?> voidedByEventId = const Value.absent(),
  }) => SyncedEventRow(
    id: id ?? this.id,
    matchId: matchId ?? this.matchId,
    serverSeq: serverSeq ?? this.serverSeq,
    json: json ?? this.json,
    recordedByPersonId: recordedByPersonId.present
        ? recordedByPersonId.value
        : this.recordedByPersonId,
    recordedByName: recordedByName.present
        ? recordedByName.value
        : this.recordedByName,
    voidedByEventId: voidedByEventId.present
        ? voidedByEventId.value
        : this.voidedByEventId,
  );
  SyncedEventRow copyWithCompanion(SyncedEventsCompanion data) {
    return SyncedEventRow(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      serverSeq: data.serverSeq.present ? data.serverSeq.value : this.serverSeq,
      json: data.json.present ? data.json.value : this.json,
      recordedByPersonId: data.recordedByPersonId.present
          ? data.recordedByPersonId.value
          : this.recordedByPersonId,
      recordedByName: data.recordedByName.present
          ? data.recordedByName.value
          : this.recordedByName,
      voidedByEventId: data.voidedByEventId.present
          ? data.voidedByEventId.value
          : this.voidedByEventId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedEventRow(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('json: $json, ')
          ..write('recordedByPersonId: $recordedByPersonId, ')
          ..write('recordedByName: $recordedByName, ')
          ..write('voidedByEventId: $voidedByEventId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    matchId,
    serverSeq,
    json,
    recordedByPersonId,
    recordedByName,
    voidedByEventId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedEventRow &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.serverSeq == this.serverSeq &&
          other.json == this.json &&
          other.recordedByPersonId == this.recordedByPersonId &&
          other.recordedByName == this.recordedByName &&
          other.voidedByEventId == this.voidedByEventId);
}

class SyncedEventsCompanion extends UpdateCompanion<SyncedEventRow> {
  final Value<String> id;
  final Value<String> matchId;
  final Value<int> serverSeq;
  final Value<String> json;
  final Value<String?> recordedByPersonId;
  final Value<String?> recordedByName;
  final Value<String?> voidedByEventId;
  final Value<int> rowid;
  const SyncedEventsCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.serverSeq = const Value.absent(),
    this.json = const Value.absent(),
    this.recordedByPersonId = const Value.absent(),
    this.recordedByName = const Value.absent(),
    this.voidedByEventId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedEventsCompanion.insert({
    required String id,
    required String matchId,
    required int serverSeq,
    required String json,
    this.recordedByPersonId = const Value.absent(),
    this.recordedByName = const Value.absent(),
    this.voidedByEventId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       matchId = Value(matchId),
       serverSeq = Value(serverSeq),
       json = Value(json);
  static Insertable<SyncedEventRow> custom({
    Expression<String>? id,
    Expression<String>? matchId,
    Expression<int>? serverSeq,
    Expression<String>? json,
    Expression<String>? recordedByPersonId,
    Expression<String>? recordedByName,
    Expression<String>? voidedByEventId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (serverSeq != null) 'server_seq': serverSeq,
      if (json != null) 'json': json,
      if (recordedByPersonId != null)
        'recorded_by_person_id': recordedByPersonId,
      if (recordedByName != null) 'recorded_by_name': recordedByName,
      if (voidedByEventId != null) 'voided_by_event_id': voidedByEventId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? matchId,
    Value<int>? serverSeq,
    Value<String>? json,
    Value<String?>? recordedByPersonId,
    Value<String?>? recordedByName,
    Value<String?>? voidedByEventId,
    Value<int>? rowid,
  }) {
    return SyncedEventsCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      serverSeq: serverSeq ?? this.serverSeq,
      json: json ?? this.json,
      recordedByPersonId: recordedByPersonId ?? this.recordedByPersonId,
      recordedByName: recordedByName ?? this.recordedByName,
      voidedByEventId: voidedByEventId ?? this.voidedByEventId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (serverSeq.present) {
      map['server_seq'] = Variable<int>(serverSeq.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (recordedByPersonId.present) {
      map['recorded_by_person_id'] = Variable<String>(recordedByPersonId.value);
    }
    if (recordedByName.present) {
      map['recorded_by_name'] = Variable<String>(recordedByName.value);
    }
    if (voidedByEventId.present) {
      map['voided_by_event_id'] = Variable<String>(voidedByEventId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncedEventsCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('serverSeq: $serverSeq, ')
          ..write('json: $json, ')
          ..write('recordedByPersonId: $recordedByPersonId, ')
          ..write('recordedByName: $recordedByName, ')
          ..write('voidedByEventId: $voidedByEventId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceTable extends Device with TableInfo<$DeviceTable, DeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [slot, deviceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slot};
  @override
  DeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceRow(
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $DeviceTable createAlias(String alias) {
    return $DeviceTable(attachedDatabase, alias);
  }
}

class DeviceRow extends DataClass implements Insertable<DeviceRow> {
  final int slot;
  final String deviceId;
  const DeviceRow({required this.slot, required this.deviceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slot'] = Variable<int>(slot);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  DeviceCompanion toCompanion(bool nullToAbsent) {
    return DeviceCompanion(slot: Value(slot), deviceId: Value(deviceId));
  }

  factory DeviceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceRow(
      slot: serializer.fromJson<int>(json['slot']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slot': serializer.toJson<int>(slot),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  DeviceRow copyWith({int? slot, String? deviceId}) =>
      DeviceRow(slot: slot ?? this.slot, deviceId: deviceId ?? this.deviceId);
  DeviceRow copyWithCompanion(DeviceCompanion data) {
    return DeviceRow(
      slot: data.slot.present ? data.slot.value : this.slot,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceRow(')
          ..write('slot: $slot, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(slot, deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceRow &&
          other.slot == this.slot &&
          other.deviceId == this.deviceId);
}

class DeviceCompanion extends UpdateCompanion<DeviceRow> {
  final Value<int> slot;
  final Value<String> deviceId;
  const DeviceCompanion({
    this.slot = const Value.absent(),
    this.deviceId = const Value.absent(),
  });
  DeviceCompanion.insert({
    this.slot = const Value.absent(),
    required String deviceId,
  }) : deviceId = Value(deviceId);
  static Insertable<DeviceRow> custom({
    Expression<int>? slot,
    Expression<String>? deviceId,
  }) {
    return RawValuesInsertable({
      if (slot != null) 'slot': slot,
      if (deviceId != null) 'device_id': deviceId,
    });
  }

  DeviceCompanion copyWith({Value<int>? slot, Value<String>? deviceId}) {
    return DeviceCompanion(
      slot: slot ?? this.slot,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceCompanion(')
          ..write('slot: $slot, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }
}

class $ClientSequencesTable extends ClientSequences
    with TableInfo<$ClientSequencesTable, ClientSequenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientSequencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastClientSeqMeta = const VerificationMeta(
    'lastClientSeq',
  );
  @override
  late final GeneratedColumn<int> lastClientSeq = GeneratedColumn<int>(
    'last_client_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [matchId, lastClientSeq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'client_sequences';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientSequenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('last_client_seq')) {
      context.handle(
        _lastClientSeqMeta,
        lastClientSeq.isAcceptableOrUnknown(
          data['last_client_seq']!,
          _lastClientSeqMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastClientSeqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matchId};
  @override
  ClientSequenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientSequenceRow(
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      lastClientSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_client_seq'],
      )!,
    );
  }

  @override
  $ClientSequencesTable createAlias(String alias) {
    return $ClientSequencesTable(attachedDatabase, alias);
  }
}

class ClientSequenceRow extends DataClass
    implements Insertable<ClientSequenceRow> {
  final String matchId;
  final int lastClientSeq;
  const ClientSequenceRow({required this.matchId, required this.lastClientSeq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['match_id'] = Variable<String>(matchId);
    map['last_client_seq'] = Variable<int>(lastClientSeq);
    return map;
  }

  ClientSequencesCompanion toCompanion(bool nullToAbsent) {
    return ClientSequencesCompanion(
      matchId: Value(matchId),
      lastClientSeq: Value(lastClientSeq),
    );
  }

  factory ClientSequenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientSequenceRow(
      matchId: serializer.fromJson<String>(json['matchId']),
      lastClientSeq: serializer.fromJson<int>(json['lastClientSeq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matchId': serializer.toJson<String>(matchId),
      'lastClientSeq': serializer.toJson<int>(lastClientSeq),
    };
  }

  ClientSequenceRow copyWith({String? matchId, int? lastClientSeq}) =>
      ClientSequenceRow(
        matchId: matchId ?? this.matchId,
        lastClientSeq: lastClientSeq ?? this.lastClientSeq,
      );
  ClientSequenceRow copyWithCompanion(ClientSequencesCompanion data) {
    return ClientSequenceRow(
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      lastClientSeq: data.lastClientSeq.present
          ? data.lastClientSeq.value
          : this.lastClientSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientSequenceRow(')
          ..write('matchId: $matchId, ')
          ..write('lastClientSeq: $lastClientSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(matchId, lastClientSeq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientSequenceRow &&
          other.matchId == this.matchId &&
          other.lastClientSeq == this.lastClientSeq);
}

class ClientSequencesCompanion extends UpdateCompanion<ClientSequenceRow> {
  final Value<String> matchId;
  final Value<int> lastClientSeq;
  final Value<int> rowid;
  const ClientSequencesCompanion({
    this.matchId = const Value.absent(),
    this.lastClientSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientSequencesCompanion.insert({
    required String matchId,
    required int lastClientSeq,
    this.rowid = const Value.absent(),
  }) : matchId = Value(matchId),
       lastClientSeq = Value(lastClientSeq);
  static Insertable<ClientSequenceRow> custom({
    Expression<String>? matchId,
    Expression<int>? lastClientSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (matchId != null) 'match_id': matchId,
      if (lastClientSeq != null) 'last_client_seq': lastClientSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientSequencesCompanion copyWith({
    Value<String>? matchId,
    Value<int>? lastClientSeq,
    Value<int>? rowid,
  }) {
    return ClientSequencesCompanion(
      matchId: matchId ?? this.matchId,
      lastClientSeq: lastClientSeq ?? this.lastClientSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (lastClientSeq.present) {
      map['last_client_seq'] = Variable<int>(lastClientSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientSequencesCompanion(')
          ..write('matchId: $matchId, ')
          ..write('lastClientSeq: $lastClientSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MatchDatabase extends GeneratedDatabase {
  _$MatchDatabase(QueryExecutor e) : super(e);
  $MatchDatabaseManager get managers => $MatchDatabaseManager(this);
  late final $MatchesCacheTable matchesCache = $MatchesCacheTable(this);
  late final $RosterCacheTable rosterCache = $RosterCacheTable(this);
  late final $PendingEventsTable pendingEvents = $PendingEventsTable(this);
  late final $SyncedEventsTable syncedEvents = $SyncedEventsTable(this);
  late final $DeviceTable device = $DeviceTable(this);
  late final $ClientSequencesTable clientSequences = $ClientSequencesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    matchesCache,
    rosterCache,
    pendingEvents,
    syncedEvents,
    device,
    clientSequences,
  ];
}

typedef $$MatchesCacheTableCreateCompanionBuilder =
    MatchesCacheCompanion Function({
      required String id,
      required String tenantId,
      required String teamId,
      required String json,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$MatchesCacheTableUpdateCompanionBuilder =
    MatchesCacheCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> teamId,
      Value<String> json,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$MatchesCacheTableFilterComposer
    extends Composer<_$MatchDatabase, $MatchesCacheTable> {
  $$MatchesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatchesCacheTableOrderingComposer
    extends Composer<_$MatchDatabase, $MatchesCacheTable> {
  $$MatchesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatchesCacheTableAnnotationComposer
    extends Composer<_$MatchDatabase, $MatchesCacheTable> {
  $$MatchesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$MatchesCacheTableTableManager
    extends
        RootTableManager<
          _$MatchDatabase,
          $MatchesCacheTable,
          MatchCacheRow,
          $$MatchesCacheTableFilterComposer,
          $$MatchesCacheTableOrderingComposer,
          $$MatchesCacheTableAnnotationComposer,
          $$MatchesCacheTableCreateCompanionBuilder,
          $$MatchesCacheTableUpdateCompanionBuilder,
          (
            MatchCacheRow,
            BaseReferences<_$MatchDatabase, $MatchesCacheTable, MatchCacheRow>,
          ),
          MatchCacheRow,
          PrefetchHooks Function()
        > {
  $$MatchesCacheTableTableManager(_$MatchDatabase db, $MatchesCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> teamId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchesCacheCompanion(
                id: id,
                tenantId: tenantId,
                teamId: teamId,
                json: json,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String teamId,
                required String json,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => MatchesCacheCompanion.insert(
                id: id,
                tenantId: tenantId,
                teamId: teamId,
                json: json,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MatchesCacheTable, MatchCacheRow>(table),
                  BaseReferences<
                    _$MatchDatabase,
                    $MatchesCacheTable,
                    MatchCacheRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatchesCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$MatchDatabase,
      $MatchesCacheTable,
      MatchCacheRow,
      $$MatchesCacheTableFilterComposer,
      $$MatchesCacheTableOrderingComposer,
      $$MatchesCacheTableAnnotationComposer,
      $$MatchesCacheTableCreateCompanionBuilder,
      $$MatchesCacheTableUpdateCompanionBuilder,
      (
        MatchCacheRow,
        BaseReferences<_$MatchDatabase, $MatchesCacheTable, MatchCacheRow>,
      ),
      MatchCacheRow,
      PrefetchHooks Function()
    >;
typedef $$RosterCacheTableCreateCompanionBuilder =
    RosterCacheCompanion Function({
      required String matchId,
      required String playerId,
      required int position,
      required String displayName,
      Value<String?> jerseyNumber,
      required bool isStarter,
      Value<int> rowid,
    });
typedef $$RosterCacheTableUpdateCompanionBuilder =
    RosterCacheCompanion Function({
      Value<String> matchId,
      Value<String> playerId,
      Value<int> position,
      Value<String> displayName,
      Value<String?> jerseyNumber,
      Value<bool> isStarter,
      Value<int> rowid,
    });

class $$RosterCacheTableFilterComposer
    extends Composer<_$MatchDatabase, $RosterCacheTable> {
  $$RosterCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStarter => $composableBuilder(
    column: $table.isStarter,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RosterCacheTableOrderingComposer
    extends Composer<_$MatchDatabase, $RosterCacheTable> {
  $$RosterCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStarter => $composableBuilder(
    column: $table.isStarter,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RosterCacheTableAnnotationComposer
    extends Composer<_$MatchDatabase, $RosterCacheTable> {
  $$RosterCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStarter =>
      $composableBuilder(column: $table.isStarter, builder: (column) => column);
}

class $$RosterCacheTableTableManager
    extends
        RootTableManager<
          _$MatchDatabase,
          $RosterCacheTable,
          RosterCacheRow,
          $$RosterCacheTableFilterComposer,
          $$RosterCacheTableOrderingComposer,
          $$RosterCacheTableAnnotationComposer,
          $$RosterCacheTableCreateCompanionBuilder,
          $$RosterCacheTableUpdateCompanionBuilder,
          (
            RosterCacheRow,
            BaseReferences<_$MatchDatabase, $RosterCacheTable, RosterCacheRow>,
          ),
          RosterCacheRow,
          PrefetchHooks Function()
        > {
  $$RosterCacheTableTableManager(_$MatchDatabase db, $RosterCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RosterCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RosterCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RosterCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> matchId = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> jerseyNumber = const Value.absent(),
                Value<bool> isStarter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RosterCacheCompanion(
                matchId: matchId,
                playerId: playerId,
                position: position,
                displayName: displayName,
                jerseyNumber: jerseyNumber,
                isStarter: isStarter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String matchId,
                required String playerId,
                required int position,
                required String displayName,
                Value<String?> jerseyNumber = const Value.absent(),
                required bool isStarter,
                Value<int> rowid = const Value.absent(),
              }) => RosterCacheCompanion.insert(
                matchId: matchId,
                playerId: playerId,
                position: position,
                displayName: displayName,
                jerseyNumber: jerseyNumber,
                isStarter: isStarter,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RosterCacheTable, RosterCacheRow>(table),
                  BaseReferences<
                    _$MatchDatabase,
                    $RosterCacheTable,
                    RosterCacheRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RosterCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$MatchDatabase,
      $RosterCacheTable,
      RosterCacheRow,
      $$RosterCacheTableFilterComposer,
      $$RosterCacheTableOrderingComposer,
      $$RosterCacheTableAnnotationComposer,
      $$RosterCacheTableCreateCompanionBuilder,
      $$RosterCacheTableUpdateCompanionBuilder,
      (
        RosterCacheRow,
        BaseReferences<_$MatchDatabase, $RosterCacheTable, RosterCacheRow>,
      ),
      RosterCacheRow,
      PrefetchHooks Function()
    >;
typedef $$PendingEventsTableCreateCompanionBuilder =
    PendingEventsCompanion Function({
      required String id,
      required String tenantId,
      required String matchId,
      required String personId,
      required String deviceId,
      required int clientSeq,
      required String type,
      Value<String?> playerId,
      required int period,
      required int clockSecondsRemaining,
      Value<String?> payload,
      required String recordedAtClient,
      required String status,
      Value<String?> rejectReason,
      Value<int?> serverSeq,
      Value<int> rowid,
    });
typedef $$PendingEventsTableUpdateCompanionBuilder =
    PendingEventsCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> matchId,
      Value<String> personId,
      Value<String> deviceId,
      Value<int> clientSeq,
      Value<String> type,
      Value<String?> playerId,
      Value<int> period,
      Value<int> clockSecondsRemaining,
      Value<String?> payload,
      Value<String> recordedAtClient,
      Value<String> status,
      Value<String?> rejectReason,
      Value<int?> serverSeq,
      Value<int> rowid,
    });

class $$PendingEventsTableFilterComposer
    extends Composer<_$MatchDatabase, $PendingEventsTable> {
  $$PendingEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientSeq => $composableBuilder(
    column: $table.clientSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clockSecondsRemaining => $composableBuilder(
    column: $table.clockSecondsRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedAtClient => $composableBuilder(
    column: $table.recordedAtClient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectReason => $composableBuilder(
    column: $table.rejectReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingEventsTableOrderingComposer
    extends Composer<_$MatchDatabase, $PendingEventsTable> {
  $$PendingEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientSeq => $composableBuilder(
    column: $table.clientSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clockSecondsRemaining => $composableBuilder(
    column: $table.clockSecondsRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedAtClient => $composableBuilder(
    column: $table.recordedAtClient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectReason => $composableBuilder(
    column: $table.rejectReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingEventsTableAnnotationComposer
    extends Composer<_$MatchDatabase, $PendingEventsTable> {
  $$PendingEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get clientSeq =>
      $composableBuilder(column: $table.clientSeq, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<int> get clockSecondsRemaining => $composableBuilder(
    column: $table.clockSecondsRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get recordedAtClient => $composableBuilder(
    column: $table.recordedAtClient,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get rejectReason => $composableBuilder(
    column: $table.rejectReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);
}

class $$PendingEventsTableTableManager
    extends
        RootTableManager<
          _$MatchDatabase,
          $PendingEventsTable,
          PendingEventRow,
          $$PendingEventsTableFilterComposer,
          $$PendingEventsTableOrderingComposer,
          $$PendingEventsTableAnnotationComposer,
          $$PendingEventsTableCreateCompanionBuilder,
          $$PendingEventsTableUpdateCompanionBuilder,
          (
            PendingEventRow,
            BaseReferences<
              _$MatchDatabase,
              $PendingEventsTable,
              PendingEventRow
            >,
          ),
          PendingEventRow,
          PrefetchHooks Function()
        > {
  $$PendingEventsTableTableManager(
    _$MatchDatabase db,
    $PendingEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> matchId = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> clientSeq = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> playerId = const Value.absent(),
                Value<int> period = const Value.absent(),
                Value<int> clockSecondsRemaining = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<String> recordedAtClient = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> rejectReason = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingEventsCompanion(
                id: id,
                tenantId: tenantId,
                matchId: matchId,
                personId: personId,
                deviceId: deviceId,
                clientSeq: clientSeq,
                type: type,
                playerId: playerId,
                period: period,
                clockSecondsRemaining: clockSecondsRemaining,
                payload: payload,
                recordedAtClient: recordedAtClient,
                status: status,
                rejectReason: rejectReason,
                serverSeq: serverSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String matchId,
                required String personId,
                required String deviceId,
                required int clientSeq,
                required String type,
                Value<String?> playerId = const Value.absent(),
                required int period,
                required int clockSecondsRemaining,
                Value<String?> payload = const Value.absent(),
                required String recordedAtClient,
                required String status,
                Value<String?> rejectReason = const Value.absent(),
                Value<int?> serverSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingEventsCompanion.insert(
                id: id,
                tenantId: tenantId,
                matchId: matchId,
                personId: personId,
                deviceId: deviceId,
                clientSeq: clientSeq,
                type: type,
                playerId: playerId,
                period: period,
                clockSecondsRemaining: clockSecondsRemaining,
                payload: payload,
                recordedAtClient: recordedAtClient,
                status: status,
                rejectReason: rejectReason,
                serverSeq: serverSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingEventsTable, PendingEventRow>(table),
                  BaseReferences<
                    _$MatchDatabase,
                    $PendingEventsTable,
                    PendingEventRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$MatchDatabase,
      $PendingEventsTable,
      PendingEventRow,
      $$PendingEventsTableFilterComposer,
      $$PendingEventsTableOrderingComposer,
      $$PendingEventsTableAnnotationComposer,
      $$PendingEventsTableCreateCompanionBuilder,
      $$PendingEventsTableUpdateCompanionBuilder,
      (
        PendingEventRow,
        BaseReferences<_$MatchDatabase, $PendingEventsTable, PendingEventRow>,
      ),
      PendingEventRow,
      PrefetchHooks Function()
    >;
typedef $$SyncedEventsTableCreateCompanionBuilder =
    SyncedEventsCompanion Function({
      required String id,
      required String matchId,
      required int serverSeq,
      required String json,
      Value<String?> recordedByPersonId,
      Value<String?> recordedByName,
      Value<String?> voidedByEventId,
      Value<int> rowid,
    });
typedef $$SyncedEventsTableUpdateCompanionBuilder =
    SyncedEventsCompanion Function({
      Value<String> id,
      Value<String> matchId,
      Value<int> serverSeq,
      Value<String> json,
      Value<String?> recordedByPersonId,
      Value<String?> recordedByName,
      Value<String?> voidedByEventId,
      Value<int> rowid,
    });

class $$SyncedEventsTableFilterComposer
    extends Composer<_$MatchDatabase, $SyncedEventsTable> {
  $$SyncedEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedByPersonId => $composableBuilder(
    column: $table.recordedByPersonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedByName => $composableBuilder(
    column: $table.recordedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voidedByEventId => $composableBuilder(
    column: $table.voidedByEventId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncedEventsTableOrderingComposer
    extends Composer<_$MatchDatabase, $SyncedEventsTable> {
  $$SyncedEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverSeq => $composableBuilder(
    column: $table.serverSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedByPersonId => $composableBuilder(
    column: $table.recordedByPersonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedByName => $composableBuilder(
    column: $table.recordedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voidedByEventId => $composableBuilder(
    column: $table.voidedByEventId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncedEventsTableAnnotationComposer
    extends Composer<_$MatchDatabase, $SyncedEventsTable> {
  $$SyncedEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<int> get serverSeq =>
      $composableBuilder(column: $table.serverSeq, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get recordedByPersonId => $composableBuilder(
    column: $table.recordedByPersonId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordedByName => $composableBuilder(
    column: $table.recordedByName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voidedByEventId => $composableBuilder(
    column: $table.voidedByEventId,
    builder: (column) => column,
  );
}

class $$SyncedEventsTableTableManager
    extends
        RootTableManager<
          _$MatchDatabase,
          $SyncedEventsTable,
          SyncedEventRow,
          $$SyncedEventsTableFilterComposer,
          $$SyncedEventsTableOrderingComposer,
          $$SyncedEventsTableAnnotationComposer,
          $$SyncedEventsTableCreateCompanionBuilder,
          $$SyncedEventsTableUpdateCompanionBuilder,
          (
            SyncedEventRow,
            BaseReferences<_$MatchDatabase, $SyncedEventsTable, SyncedEventRow>,
          ),
          SyncedEventRow,
          PrefetchHooks Function()
        > {
  $$SyncedEventsTableTableManager(_$MatchDatabase db, $SyncedEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncedEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncedEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncedEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> matchId = const Value.absent(),
                Value<int> serverSeq = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String?> recordedByPersonId = const Value.absent(),
                Value<String?> recordedByName = const Value.absent(),
                Value<String?> voidedByEventId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedEventsCompanion(
                id: id,
                matchId: matchId,
                serverSeq: serverSeq,
                json: json,
                recordedByPersonId: recordedByPersonId,
                recordedByName: recordedByName,
                voidedByEventId: voidedByEventId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String matchId,
                required int serverSeq,
                required String json,
                Value<String?> recordedByPersonId = const Value.absent(),
                Value<String?> recordedByName = const Value.absent(),
                Value<String?> voidedByEventId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedEventsCompanion.insert(
                id: id,
                matchId: matchId,
                serverSeq: serverSeq,
                json: json,
                recordedByPersonId: recordedByPersonId,
                recordedByName: recordedByName,
                voidedByEventId: voidedByEventId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncedEventsTable, SyncedEventRow>(table),
                  BaseReferences<
                    _$MatchDatabase,
                    $SyncedEventsTable,
                    SyncedEventRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncedEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$MatchDatabase,
      $SyncedEventsTable,
      SyncedEventRow,
      $$SyncedEventsTableFilterComposer,
      $$SyncedEventsTableOrderingComposer,
      $$SyncedEventsTableAnnotationComposer,
      $$SyncedEventsTableCreateCompanionBuilder,
      $$SyncedEventsTableUpdateCompanionBuilder,
      (
        SyncedEventRow,
        BaseReferences<_$MatchDatabase, $SyncedEventsTable, SyncedEventRow>,
      ),
      SyncedEventRow,
      PrefetchHooks Function()
    >;
typedef $$DeviceTableCreateCompanionBuilder = DeviceCompanion Function({
  Value<int> slot,
  required String deviceId,
});
typedef $$DeviceTableUpdateCompanionBuilder = DeviceCompanion Function({
  Value<int> slot,
  Value<String> deviceId,
});

class $$DeviceTableFilterComposer
    extends Composer<_$MatchDatabase, $DeviceTable> {
  $$DeviceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceTableOrderingComposer
    extends Composer<_$MatchDatabase, $DeviceTable> {
  $$DeviceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceTableAnnotationComposer
    extends Composer<_$MatchDatabase, $DeviceTable> {
  $$DeviceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$DeviceTableTableManager
    extends
        RootTableManager<
          _$MatchDatabase,
          $DeviceTable,
          DeviceRow,
          $$DeviceTableFilterComposer,
          $$DeviceTableOrderingComposer,
          $$DeviceTableAnnotationComposer,
          $$DeviceTableCreateCompanionBuilder,
          $$DeviceTableUpdateCompanionBuilder,
          (DeviceRow, BaseReferences<_$MatchDatabase, $DeviceTable, DeviceRow>),
          DeviceRow,
          PrefetchHooks Function()
        > {
  $$DeviceTableTableManager(_$MatchDatabase db, $DeviceTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> slot = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
          }) => DeviceCompanion(slot: slot, deviceId: deviceId),
          createCompanionCallback: ({
            Value<int> slot = const Value.absent(),
            required String deviceId,
          }) => DeviceCompanion.insert(slot: slot, deviceId: deviceId),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DeviceTable, DeviceRow>(table),
                  BaseReferences<_$MatchDatabase, $DeviceTable, DeviceRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceTableProcessedTableManager =
    ProcessedTableManager<
      _$MatchDatabase,
      $DeviceTable,
      DeviceRow,
      $$DeviceTableFilterComposer,
      $$DeviceTableOrderingComposer,
      $$DeviceTableAnnotationComposer,
      $$DeviceTableCreateCompanionBuilder,
      $$DeviceTableUpdateCompanionBuilder,
      (DeviceRow, BaseReferences<_$MatchDatabase, $DeviceTable, DeviceRow>),
      DeviceRow,
      PrefetchHooks Function()
    >;
typedef $$ClientSequencesTableCreateCompanionBuilder =
    ClientSequencesCompanion Function({
      required String matchId,
      required int lastClientSeq,
      Value<int> rowid,
    });
typedef $$ClientSequencesTableUpdateCompanionBuilder =
    ClientSequencesCompanion Function({
      Value<String> matchId,
      Value<int> lastClientSeq,
      Value<int> rowid,
    });

class $$ClientSequencesTableFilterComposer
    extends Composer<_$MatchDatabase, $ClientSequencesTable> {
  $$ClientSequencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastClientSeq => $composableBuilder(
    column: $table.lastClientSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientSequencesTableOrderingComposer
    extends Composer<_$MatchDatabase, $ClientSequencesTable> {
  $$ClientSequencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastClientSeq => $composableBuilder(
    column: $table.lastClientSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientSequencesTableAnnotationComposer
    extends Composer<_$MatchDatabase, $ClientSequencesTable> {
  $$ClientSequencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<int> get lastClientSeq => $composableBuilder(
    column: $table.lastClientSeq,
    builder: (column) => column,
  );
}

class $$ClientSequencesTableTableManager
    extends
        RootTableManager<
          _$MatchDatabase,
          $ClientSequencesTable,
          ClientSequenceRow,
          $$ClientSequencesTableFilterComposer,
          $$ClientSequencesTableOrderingComposer,
          $$ClientSequencesTableAnnotationComposer,
          $$ClientSequencesTableCreateCompanionBuilder,
          $$ClientSequencesTableUpdateCompanionBuilder,
          (
            ClientSequenceRow,
            BaseReferences<
              _$MatchDatabase,
              $ClientSequencesTable,
              ClientSequenceRow
            >,
          ),
          ClientSequenceRow,
          PrefetchHooks Function()
        > {
  $$ClientSequencesTableTableManager(
    _$MatchDatabase db,
    $ClientSequencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientSequencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientSequencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientSequencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> matchId = const Value.absent(),
                Value<int> lastClientSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientSequencesCompanion(
                matchId: matchId,
                lastClientSeq: lastClientSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String matchId,
                required int lastClientSeq,
                Value<int> rowid = const Value.absent(),
              }) => ClientSequencesCompanion.insert(
                matchId: matchId,
                lastClientSeq: lastClientSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClientSequencesTable, ClientSequenceRow>(table),
                  BaseReferences<
                    _$MatchDatabase,
                    $ClientSequencesTable,
                    ClientSequenceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientSequencesTableProcessedTableManager =
    ProcessedTableManager<
      _$MatchDatabase,
      $ClientSequencesTable,
      ClientSequenceRow,
      $$ClientSequencesTableFilterComposer,
      $$ClientSequencesTableOrderingComposer,
      $$ClientSequencesTableAnnotationComposer,
      $$ClientSequencesTableCreateCompanionBuilder,
      $$ClientSequencesTableUpdateCompanionBuilder,
      (
        ClientSequenceRow,
        BaseReferences<
          _$MatchDatabase,
          $ClientSequencesTable,
          ClientSequenceRow
        >,
      ),
      ClientSequenceRow,
      PrefetchHooks Function()
    >;

class $MatchDatabaseManager {
  final _$MatchDatabase _db;
  $MatchDatabaseManager(this._db);
  $$MatchesCacheTableTableManager get matchesCache =>
      $$MatchesCacheTableTableManager(_db, _db.matchesCache);
  $$RosterCacheTableTableManager get rosterCache =>
      $$RosterCacheTableTableManager(_db, _db.rosterCache);
  $$PendingEventsTableTableManager get pendingEvents =>
      $$PendingEventsTableTableManager(_db, _db.pendingEvents);
  $$SyncedEventsTableTableManager get syncedEvents =>
      $$SyncedEventsTableTableManager(_db, _db.syncedEvents);
  $$DeviceTableTableManager get device =>
      $$DeviceTableTableManager(_db, _db.device);
  $$ClientSequencesTableTableManager get clientSequences =>
      $$ClientSequencesTableTableManager(_db, _db.clientSequences);
}
