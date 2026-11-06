// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_plan_item_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdatePlanItemRequestClearEnum
    _$updatePlanItemRequestClearEnum_description =
    const UpdatePlanItemRequestClearEnum._('description');
const UpdatePlanItemRequestClearEnum
    _$updatePlanItemRequestClearEnum_durationMinutes =
    const UpdatePlanItemRequestClearEnum._('durationMinutes');
const UpdatePlanItemRequestClearEnum _$updatePlanItemRequestClearEnum_sets =
    const UpdatePlanItemRequestClearEnum._('sets');
const UpdatePlanItemRequestClearEnum
    _$updatePlanItemRequestClearEnum_repetitions =
    const UpdatePlanItemRequestClearEnum._('repetitions');
const UpdatePlanItemRequestClearEnum _$updatePlanItemRequestClearEnum_videoUrl =
    const UpdatePlanItemRequestClearEnum._('videoUrl');
const UpdatePlanItemRequestClearEnum
    _$updatePlanItemRequestClearEnum_unknownDefaultOpenApi =
    const UpdatePlanItemRequestClearEnum._('unknownDefaultOpenApi');

UpdatePlanItemRequestClearEnum _$updatePlanItemRequestClearEnumValueOf(
    String name) {
  switch (name) {
    case 'description':
      return _$updatePlanItemRequestClearEnum_description;
    case 'durationMinutes':
      return _$updatePlanItemRequestClearEnum_durationMinutes;
    case 'sets':
      return _$updatePlanItemRequestClearEnum_sets;
    case 'repetitions':
      return _$updatePlanItemRequestClearEnum_repetitions;
    case 'videoUrl':
      return _$updatePlanItemRequestClearEnum_videoUrl;
    case 'unknownDefaultOpenApi':
      return _$updatePlanItemRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updatePlanItemRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdatePlanItemRequestClearEnum>
    _$updatePlanItemRequestClearEnumValues = BuiltSet<
        UpdatePlanItemRequestClearEnum>(const <UpdatePlanItemRequestClearEnum>[
  _$updatePlanItemRequestClearEnum_description,
  _$updatePlanItemRequestClearEnum_durationMinutes,
  _$updatePlanItemRequestClearEnum_sets,
  _$updatePlanItemRequestClearEnum_repetitions,
  _$updatePlanItemRequestClearEnum_videoUrl,
  _$updatePlanItemRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdatePlanItemRequestClearEnum>
    _$updatePlanItemRequestClearEnumSerializer =
    _$UpdatePlanItemRequestClearEnumSerializer();

class _$UpdatePlanItemRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdatePlanItemRequestClearEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'description': 'description',
    'durationMinutes': 'durationMinutes',
    'sets': 'sets',
    'repetitions': 'repetitions',
    'videoUrl': 'videoUrl',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'description': 'description',
    'durationMinutes': 'durationMinutes',
    'sets': 'sets',
    'repetitions': 'repetitions',
    'videoUrl': 'videoUrl',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdatePlanItemRequestClearEnum];
  @override
  final String wireName = 'UpdatePlanItemRequestClearEnum';

  @override
  Object serialize(
          Serializers serializers, UpdatePlanItemRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdatePlanItemRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdatePlanItemRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdatePlanItemRequest extends UpdatePlanItemRequest {
  @override
  final String? title;
  @override
  final String? description;
  @override
  final int? durationMinutes;
  @override
  final int? sets;
  @override
  final int? repetitions;
  @override
  final String? videoUrl;
  @override
  final BuiltSet<UpdatePlanItemRequestClearEnum>? clear;

  factory _$UpdatePlanItemRequest(
          [void Function(UpdatePlanItemRequestBuilder)? updates]) =>
      (UpdatePlanItemRequestBuilder()..update(updates))._build();

  _$UpdatePlanItemRequest._(
      {this.title,
      this.description,
      this.durationMinutes,
      this.sets,
      this.repetitions,
      this.videoUrl,
      this.clear})
      : super._();
  @override
  UpdatePlanItemRequest rebuild(
          void Function(UpdatePlanItemRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdatePlanItemRequestBuilder toBuilder() =>
      UpdatePlanItemRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePlanItemRequest &&
        title == other.title &&
        description == other.description &&
        durationMinutes == other.durationMinutes &&
        sets == other.sets &&
        repetitions == other.repetitions &&
        videoUrl == other.videoUrl &&
        clear == other.clear;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, durationMinutes.hashCode);
    _$hash = $jc(_$hash, sets.hashCode);
    _$hash = $jc(_$hash, repetitions.hashCode);
    _$hash = $jc(_$hash, videoUrl.hashCode);
    _$hash = $jc(_$hash, clear.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePlanItemRequest')
          ..add('title', title)
          ..add('description', description)
          ..add('durationMinutes', durationMinutes)
          ..add('sets', sets)
          ..add('repetitions', repetitions)
          ..add('videoUrl', videoUrl)
          ..add('clear', clear))
        .toString();
  }
}

class UpdatePlanItemRequestBuilder
    implements Builder<UpdatePlanItemRequest, UpdatePlanItemRequestBuilder> {
  _$UpdatePlanItemRequest? _$v;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  int? _durationMinutes;
  int? get durationMinutes => _$this._durationMinutes;
  set durationMinutes(int? durationMinutes) =>
      _$this._durationMinutes = durationMinutes;

  int? _sets;
  int? get sets => _$this._sets;
  set sets(int? sets) => _$this._sets = sets;

  int? _repetitions;
  int? get repetitions => _$this._repetitions;
  set repetitions(int? repetitions) => _$this._repetitions = repetitions;

  String? _videoUrl;
  String? get videoUrl => _$this._videoUrl;
  set videoUrl(String? videoUrl) => _$this._videoUrl = videoUrl;

  SetBuilder<UpdatePlanItemRequestClearEnum>? _clear;
  SetBuilder<UpdatePlanItemRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdatePlanItemRequestClearEnum>();
  set clear(SetBuilder<UpdatePlanItemRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdatePlanItemRequestBuilder() {
    UpdatePlanItemRequest._defaults(this);
  }

  UpdatePlanItemRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _description = $v.description;
      _durationMinutes = $v.durationMinutes;
      _sets = $v.sets;
      _repetitions = $v.repetitions;
      _videoUrl = $v.videoUrl;
      _clear = $v.clear?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePlanItemRequest other) {
    _$v = other as _$UpdatePlanItemRequest;
  }

  @override
  void update(void Function(UpdatePlanItemRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePlanItemRequest build() => _build();

  _$UpdatePlanItemRequest _build() {
    _$UpdatePlanItemRequest _$result;
    try {
      _$result = _$v ??
          _$UpdatePlanItemRequest._(
            title: title,
            description: description,
            durationMinutes: durationMinutes,
            sets: sets,
            repetitions: repetitions,
            videoUrl: videoUrl,
            clear: _clear?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'clear';
        _clear?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'UpdatePlanItemRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
