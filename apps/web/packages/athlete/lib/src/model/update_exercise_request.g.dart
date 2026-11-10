// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_exercise_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateExerciseRequestClearEnum
    _$updateExerciseRequestClearEnum_description =
    const UpdateExerciseRequestClearEnum._('description');
const UpdateExerciseRequestClearEnum
    _$updateExerciseRequestClearEnum_durationMinutes =
    const UpdateExerciseRequestClearEnum._('durationMinutes');
const UpdateExerciseRequestClearEnum _$updateExerciseRequestClearEnum_sets =
    const UpdateExerciseRequestClearEnum._('sets');
const UpdateExerciseRequestClearEnum
    _$updateExerciseRequestClearEnum_repetitions =
    const UpdateExerciseRequestClearEnum._('repetitions');
const UpdateExerciseRequestClearEnum _$updateExerciseRequestClearEnum_videoUrl =
    const UpdateExerciseRequestClearEnum._('videoUrl');
const UpdateExerciseRequestClearEnum
    _$updateExerciseRequestClearEnum_unknownDefaultOpenApi =
    const UpdateExerciseRequestClearEnum._('unknownDefaultOpenApi');

UpdateExerciseRequestClearEnum _$updateExerciseRequestClearEnumValueOf(
    String name) {
  switch (name) {
    case 'description':
      return _$updateExerciseRequestClearEnum_description;
    case 'durationMinutes':
      return _$updateExerciseRequestClearEnum_durationMinutes;
    case 'sets':
      return _$updateExerciseRequestClearEnum_sets;
    case 'repetitions':
      return _$updateExerciseRequestClearEnum_repetitions;
    case 'videoUrl':
      return _$updateExerciseRequestClearEnum_videoUrl;
    case 'unknownDefaultOpenApi':
      return _$updateExerciseRequestClearEnum_unknownDefaultOpenApi;
    default:
      return _$updateExerciseRequestClearEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<UpdateExerciseRequestClearEnum>
    _$updateExerciseRequestClearEnumValues = BuiltSet<
        UpdateExerciseRequestClearEnum>(const <UpdateExerciseRequestClearEnum>[
  _$updateExerciseRequestClearEnum_description,
  _$updateExerciseRequestClearEnum_durationMinutes,
  _$updateExerciseRequestClearEnum_sets,
  _$updateExerciseRequestClearEnum_repetitions,
  _$updateExerciseRequestClearEnum_videoUrl,
  _$updateExerciseRequestClearEnum_unknownDefaultOpenApi,
]);

Serializer<UpdateExerciseRequestClearEnum>
    _$updateExerciseRequestClearEnumSerializer =
    _$UpdateExerciseRequestClearEnumSerializer();

class _$UpdateExerciseRequestClearEnumSerializer
    implements PrimitiveSerializer<UpdateExerciseRequestClearEnum> {
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
  final Iterable<Type> types = const <Type>[UpdateExerciseRequestClearEnum];
  @override
  final String wireName = 'UpdateExerciseRequestClearEnum';

  @override
  Object serialize(
          Serializers serializers, UpdateExerciseRequestClearEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  UpdateExerciseRequestClearEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UpdateExerciseRequestClearEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$UpdateExerciseRequest extends UpdateExerciseRequest {
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
  final BuiltSet<UpdateExerciseRequestClearEnum>? clear;

  factory _$UpdateExerciseRequest(
          [void Function(UpdateExerciseRequestBuilder)? updates]) =>
      (UpdateExerciseRequestBuilder()..update(updates))._build();

  _$UpdateExerciseRequest._(
      {this.title,
      this.description,
      this.durationMinutes,
      this.sets,
      this.repetitions,
      this.videoUrl,
      this.clear})
      : super._();
  @override
  UpdateExerciseRequest rebuild(
          void Function(UpdateExerciseRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateExerciseRequestBuilder toBuilder() =>
      UpdateExerciseRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateExerciseRequest &&
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
    return (newBuiltValueToStringHelper(r'UpdateExerciseRequest')
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

class UpdateExerciseRequestBuilder
    implements Builder<UpdateExerciseRequest, UpdateExerciseRequestBuilder> {
  _$UpdateExerciseRequest? _$v;

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

  SetBuilder<UpdateExerciseRequestClearEnum>? _clear;
  SetBuilder<UpdateExerciseRequestClearEnum> get clear =>
      _$this._clear ??= SetBuilder<UpdateExerciseRequestClearEnum>();
  set clear(SetBuilder<UpdateExerciseRequestClearEnum>? clear) =>
      _$this._clear = clear;

  UpdateExerciseRequestBuilder() {
    UpdateExerciseRequest._defaults(this);
  }

  UpdateExerciseRequestBuilder get _$this {
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
  void replace(UpdateExerciseRequest other) {
    _$v = other as _$UpdateExerciseRequest;
  }

  @override
  void update(void Function(UpdateExerciseRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateExerciseRequest build() => _build();

  _$UpdateExerciseRequest _build() {
    _$UpdateExerciseRequest _$result;
    try {
      _$result = _$v ??
          _$UpdateExerciseRequest._(
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
            r'UpdateExerciseRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
