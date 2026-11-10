//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'exercise.g.dart';

/// A catalogue exercise. A global one (`global`) is read-only and its `title` and `description` follow `Accept-Language` (fallback `en`), as a template's do; the academy's own are returned as stored. 
///
/// Properties:
/// * [title] 
/// * [description] 
/// * [durationMinutes] 
/// * [sets] 
/// * [repetitions] 
/// * [videoUrl] 
/// * [id] 
/// * [nameKey] - Stable key of a global exercise (e.g. `cooper-test`), the same in every language; null for the academy's own.
/// * [global] - Platform-provided, read-only exercise.
/// * [archived] - Archived exercises (the academy's own) are hidden from the catalogue and cannot be added.
@BuiltValue()
abstract class Exercise implements Built<Exercise, ExerciseBuilder> {
  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'durationMinutes')
  int? get durationMinutes;

  @BuiltValueField(wireName: r'sets')
  int? get sets;

  @BuiltValueField(wireName: r'repetitions')
  int? get repetitions;

  @BuiltValueField(wireName: r'videoUrl')
  String? get videoUrl;

  @BuiltValueField(wireName: r'id')
  String get id;

  /// Stable key of a global exercise (e.g. `cooper-test`), the same in every language; null for the academy's own.
  @BuiltValueField(wireName: r'nameKey')
  String? get nameKey;

  /// Platform-provided, read-only exercise.
  @BuiltValueField(wireName: r'global')
  bool get global;

  /// Archived exercises (the academy's own) are hidden from the catalogue and cannot be added.
  @BuiltValueField(wireName: r'archived')
  bool get archived;

  Exercise._();

  factory Exercise([void updates(ExerciseBuilder b)]) = _$Exercise;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExerciseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Exercise> get serializer => _$ExerciseSerializer();
}

class _$ExerciseSerializer implements PrimitiveSerializer<Exercise> {
  @override
  final Iterable<Type> types = const [Exercise, _$Exercise];

  @override
  final String wireName = r'Exercise';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Exercise object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.durationMinutes != null) {
      yield r'durationMinutes';
      yield serializers.serialize(
        object.durationMinutes,
        specifiedType: const FullType(int),
      );
    }
    if (object.sets != null) {
      yield r'sets';
      yield serializers.serialize(
        object.sets,
        specifiedType: const FullType(int),
      );
    }
    if (object.repetitions != null) {
      yield r'repetitions';
      yield serializers.serialize(
        object.repetitions,
        specifiedType: const FullType(int),
      );
    }
    if (object.videoUrl != null) {
      yield r'videoUrl';
      yield serializers.serialize(
        object.videoUrl,
        specifiedType: const FullType(String),
      );
    }
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.nameKey != null) {
      yield r'nameKey';
      yield serializers.serialize(
        object.nameKey,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'global';
    yield serializers.serialize(
      object.global,
      specifiedType: const FullType(bool),
    );
    yield r'archived';
    yield serializers.serialize(
      object.archived,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Exercise object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExerciseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.description = valueDes;
          break;
        case r'durationMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.durationMinutes = valueDes;
          break;
        case r'sets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.sets = valueDes;
          break;
        case r'repetitions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.repetitions = valueDes;
          break;
        case r'videoUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.videoUrl = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'nameKey':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nameKey = valueDes;
          break;
        case r'global':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.global = valueDes;
          break;
        case r'archived':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.archived = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Exercise deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExerciseBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}


