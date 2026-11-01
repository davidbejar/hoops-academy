// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_training_plan_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateTrainingPlanRequest extends UpdateTrainingPlanRequest {
  @override
  final String? name;
  @override
  final String? description;

  factory _$UpdateTrainingPlanRequest(
          [void Function(UpdateTrainingPlanRequestBuilder)? updates]) =>
      (UpdateTrainingPlanRequestBuilder()..update(updates))._build();

  _$UpdateTrainingPlanRequest._({this.name, this.description}) : super._();
  @override
  UpdateTrainingPlanRequest rebuild(
          void Function(UpdateTrainingPlanRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTrainingPlanRequestBuilder toBuilder() =>
      UpdateTrainingPlanRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTrainingPlanRequest &&
        name == other.name &&
        description == other.description;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTrainingPlanRequest')
          ..add('name', name)
          ..add('description', description))
        .toString();
  }
}

class UpdateTrainingPlanRequestBuilder
    implements
        Builder<UpdateTrainingPlanRequest, UpdateTrainingPlanRequestBuilder> {
  _$UpdateTrainingPlanRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  UpdateTrainingPlanRequestBuilder() {
    UpdateTrainingPlanRequest._defaults(this);
  }

  UpdateTrainingPlanRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _description = $v.description;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTrainingPlanRequest other) {
    _$v = other as _$UpdateTrainingPlanRequest;
  }

  @override
  void update(void Function(UpdateTrainingPlanRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTrainingPlanRequest build() => _build();

  _$UpdateTrainingPlanRequest _build() {
    final _$result = _$v ??
        _$UpdateTrainingPlanRequest._(
          name: name,
          description: description,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
