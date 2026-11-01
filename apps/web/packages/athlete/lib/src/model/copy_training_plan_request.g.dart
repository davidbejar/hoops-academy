// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'copy_training_plan_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CopyTrainingPlanRequest extends CopyTrainingPlanRequest {
  @override
  final String? name;

  factory _$CopyTrainingPlanRequest(
          [void Function(CopyTrainingPlanRequestBuilder)? updates]) =>
      (CopyTrainingPlanRequestBuilder()..update(updates))._build();

  _$CopyTrainingPlanRequest._({this.name}) : super._();
  @override
  CopyTrainingPlanRequest rebuild(
          void Function(CopyTrainingPlanRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CopyTrainingPlanRequestBuilder toBuilder() =>
      CopyTrainingPlanRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CopyTrainingPlanRequest && name == other.name;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CopyTrainingPlanRequest')
          ..add('name', name))
        .toString();
  }
}

class CopyTrainingPlanRequestBuilder
    implements
        Builder<CopyTrainingPlanRequest, CopyTrainingPlanRequestBuilder> {
  _$CopyTrainingPlanRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  CopyTrainingPlanRequestBuilder() {
    CopyTrainingPlanRequest._defaults(this);
  }

  CopyTrainingPlanRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CopyTrainingPlanRequest other) {
    _$v = other as _$CopyTrainingPlanRequest;
  }

  @override
  void update(void Function(CopyTrainingPlanRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CopyTrainingPlanRequest build() => _build();

  _$CopyTrainingPlanRequest _build() {
    final _$result = _$v ??
        _$CopyTrainingPlanRequest._(
          name: name,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
