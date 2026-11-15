// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due_generation.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DueGeneration extends DueGeneration {
  @override
  final String feePlanId;
  @override
  final String period;
  @override
  final Date periodStart;
  @override
  final Date periodEnd;
  @override
  final bool preview;
  @override
  final int created;
  @override
  final int existing;
  @override
  final BuiltList<GeneratedDue> dues;

  factory _$DueGeneration([void Function(DueGenerationBuilder)? updates]) =>
      (DueGenerationBuilder()..update(updates))._build();

  _$DueGeneration._(
      {required this.feePlanId,
      required this.period,
      required this.periodStart,
      required this.periodEnd,
      required this.preview,
      required this.created,
      required this.existing,
      required this.dues})
      : super._();
  @override
  DueGeneration rebuild(void Function(DueGenerationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DueGenerationBuilder toBuilder() => DueGenerationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DueGeneration &&
        feePlanId == other.feePlanId &&
        period == other.period &&
        periodStart == other.periodStart &&
        periodEnd == other.periodEnd &&
        preview == other.preview &&
        created == other.created &&
        existing == other.existing &&
        dues == other.dues;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, feePlanId.hashCode);
    _$hash = $jc(_$hash, period.hashCode);
    _$hash = $jc(_$hash, periodStart.hashCode);
    _$hash = $jc(_$hash, periodEnd.hashCode);
    _$hash = $jc(_$hash, preview.hashCode);
    _$hash = $jc(_$hash, created.hashCode);
    _$hash = $jc(_$hash, existing.hashCode);
    _$hash = $jc(_$hash, dues.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DueGeneration')
          ..add('feePlanId', feePlanId)
          ..add('period', period)
          ..add('periodStart', periodStart)
          ..add('periodEnd', periodEnd)
          ..add('preview', preview)
          ..add('created', created)
          ..add('existing', existing)
          ..add('dues', dues))
        .toString();
  }
}

class DueGenerationBuilder
    implements Builder<DueGeneration, DueGenerationBuilder> {
  _$DueGeneration? _$v;

  String? _feePlanId;
  String? get feePlanId => _$this._feePlanId;
  set feePlanId(String? feePlanId) => _$this._feePlanId = feePlanId;

  String? _period;
  String? get period => _$this._period;
  set period(String? period) => _$this._period = period;

  Date? _periodStart;
  Date? get periodStart => _$this._periodStart;
  set periodStart(Date? periodStart) => _$this._periodStart = periodStart;

  Date? _periodEnd;
  Date? get periodEnd => _$this._periodEnd;
  set periodEnd(Date? periodEnd) => _$this._periodEnd = periodEnd;

  bool? _preview;
  bool? get preview => _$this._preview;
  set preview(bool? preview) => _$this._preview = preview;

  int? _created;
  int? get created => _$this._created;
  set created(int? created) => _$this._created = created;

  int? _existing;
  int? get existing => _$this._existing;
  set existing(int? existing) => _$this._existing = existing;

  ListBuilder<GeneratedDue>? _dues;
  ListBuilder<GeneratedDue> get dues =>
      _$this._dues ??= ListBuilder<GeneratedDue>();
  set dues(ListBuilder<GeneratedDue>? dues) => _$this._dues = dues;

  DueGenerationBuilder() {
    DueGeneration._defaults(this);
  }

  DueGenerationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _feePlanId = $v.feePlanId;
      _period = $v.period;
      _periodStart = $v.periodStart;
      _periodEnd = $v.periodEnd;
      _preview = $v.preview;
      _created = $v.created;
      _existing = $v.existing;
      _dues = $v.dues.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DueGeneration other) {
    _$v = other as _$DueGeneration;
  }

  @override
  void update(void Function(DueGenerationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DueGeneration build() => _build();

  _$DueGeneration _build() {
    _$DueGeneration _$result;
    try {
      _$result = _$v ??
          _$DueGeneration._(
            feePlanId: BuiltValueNullFieldError.checkNotNull(
                feePlanId, r'DueGeneration', 'feePlanId'),
            period: BuiltValueNullFieldError.checkNotNull(
                period, r'DueGeneration', 'period'),
            periodStart: BuiltValueNullFieldError.checkNotNull(
                periodStart, r'DueGeneration', 'periodStart'),
            periodEnd: BuiltValueNullFieldError.checkNotNull(
                periodEnd, r'DueGeneration', 'periodEnd'),
            preview: BuiltValueNullFieldError.checkNotNull(
                preview, r'DueGeneration', 'preview'),
            created: BuiltValueNullFieldError.checkNotNull(
                created, r'DueGeneration', 'created'),
            existing: BuiltValueNullFieldError.checkNotNull(
                existing, r'DueGeneration', 'existing'),
            dues: dues.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'dues';
        dues.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DueGeneration', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
