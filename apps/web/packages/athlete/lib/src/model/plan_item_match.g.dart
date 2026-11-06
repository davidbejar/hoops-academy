// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_item_match.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanItemMatch extends PlanItemMatch {
  @override
  final String id;
  @override
  final String planId;
  @override
  final String title;

  factory _$PlanItemMatch([void Function(PlanItemMatchBuilder)? updates]) =>
      (PlanItemMatchBuilder()..update(updates))._build();

  _$PlanItemMatch._(
      {required this.id, required this.planId, required this.title})
      : super._();
  @override
  PlanItemMatch rebuild(void Function(PlanItemMatchBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanItemMatchBuilder toBuilder() => PlanItemMatchBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanItemMatch &&
        id == other.id &&
        planId == other.planId &&
        title == other.title;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, planId.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanItemMatch')
          ..add('id', id)
          ..add('planId', planId)
          ..add('title', title))
        .toString();
  }
}

class PlanItemMatchBuilder
    implements Builder<PlanItemMatch, PlanItemMatchBuilder> {
  _$PlanItemMatch? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _planId;
  String? get planId => _$this._planId;
  set planId(String? planId) => _$this._planId = planId;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  PlanItemMatchBuilder() {
    PlanItemMatch._defaults(this);
  }

  PlanItemMatchBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _planId = $v.planId;
      _title = $v.title;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanItemMatch other) {
    _$v = other as _$PlanItemMatch;
  }

  @override
  void update(void Function(PlanItemMatchBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanItemMatch build() => _build();

  _$PlanItemMatch _build() {
    final _$result = _$v ??
        _$PlanItemMatch._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'PlanItemMatch', 'id'),
          planId: BuiltValueNullFieldError.checkNotNull(
              planId, r'PlanItemMatch', 'planId'),
          title: BuiltValueNullFieldError.checkNotNull(
              title, r'PlanItemMatch', 'title'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
