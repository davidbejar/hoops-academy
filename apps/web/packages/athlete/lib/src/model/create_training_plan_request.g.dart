// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_training_plan_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateTrainingPlanRequest extends CreateTrainingPlanRequest {
  @override
  final String name;
  @override
  final String? description;
  @override
  final BuiltList<PlanItemInput>? items;

  factory _$CreateTrainingPlanRequest(
          [void Function(CreateTrainingPlanRequestBuilder)? updates]) =>
      (CreateTrainingPlanRequestBuilder()..update(updates))._build();

  _$CreateTrainingPlanRequest._(
      {required this.name, this.description, this.items})
      : super._();
  @override
  CreateTrainingPlanRequest rebuild(
          void Function(CreateTrainingPlanRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateTrainingPlanRequestBuilder toBuilder() =>
      CreateTrainingPlanRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateTrainingPlanRequest &&
        name == other.name &&
        description == other.description &&
        items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateTrainingPlanRequest')
          ..add('name', name)
          ..add('description', description)
          ..add('items', items))
        .toString();
  }
}

class CreateTrainingPlanRequestBuilder
    implements
        Builder<CreateTrainingPlanRequest, CreateTrainingPlanRequestBuilder> {
  _$CreateTrainingPlanRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  ListBuilder<PlanItemInput>? _items;
  ListBuilder<PlanItemInput> get items =>
      _$this._items ??= ListBuilder<PlanItemInput>();
  set items(ListBuilder<PlanItemInput>? items) => _$this._items = items;

  CreateTrainingPlanRequestBuilder() {
    CreateTrainingPlanRequest._defaults(this);
  }

  CreateTrainingPlanRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _description = $v.description;
      _items = $v.items?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateTrainingPlanRequest other) {
    _$v = other as _$CreateTrainingPlanRequest;
  }

  @override
  void update(void Function(CreateTrainingPlanRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateTrainingPlanRequest build() => _build();

  _$CreateTrainingPlanRequest _build() {
    _$CreateTrainingPlanRequest _$result;
    try {
      _$result = _$v ??
          _$CreateTrainingPlanRequest._(
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'CreateTrainingPlanRequest', 'name'),
            description: description,
            items: _items?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        _items?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CreateTrainingPlanRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
