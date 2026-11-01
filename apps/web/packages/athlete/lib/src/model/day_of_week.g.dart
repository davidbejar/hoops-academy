// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_of_week.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DayOfWeek _$MONDAY = const DayOfWeek._('MONDAY');
const DayOfWeek _$TUESDAY = const DayOfWeek._('TUESDAY');
const DayOfWeek _$WEDNESDAY = const DayOfWeek._('WEDNESDAY');
const DayOfWeek _$THURSDAY = const DayOfWeek._('THURSDAY');
const DayOfWeek _$FRIDAY = const DayOfWeek._('FRIDAY');
const DayOfWeek _$SATURDAY = const DayOfWeek._('SATURDAY');
const DayOfWeek _$SUNDAY = const DayOfWeek._('SUNDAY');
const DayOfWeek _$unknownDefaultOpenApi =
    const DayOfWeek._('unknownDefaultOpenApi');

DayOfWeek _$valueOf(String name) {
  switch (name) {
    case 'MONDAY':
      return _$MONDAY;
    case 'TUESDAY':
      return _$TUESDAY;
    case 'WEDNESDAY':
      return _$WEDNESDAY;
    case 'THURSDAY':
      return _$THURSDAY;
    case 'FRIDAY':
      return _$FRIDAY;
    case 'SATURDAY':
      return _$SATURDAY;
    case 'SUNDAY':
      return _$SUNDAY;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<DayOfWeek> _$values = BuiltSet<DayOfWeek>(const <DayOfWeek>[
  _$MONDAY,
  _$TUESDAY,
  _$WEDNESDAY,
  _$THURSDAY,
  _$FRIDAY,
  _$SATURDAY,
  _$SUNDAY,
  _$unknownDefaultOpenApi,
]);

class _$DayOfWeekMeta {
  const _$DayOfWeekMeta();
  DayOfWeek get MONDAY => _$MONDAY;
  DayOfWeek get TUESDAY => _$TUESDAY;
  DayOfWeek get WEDNESDAY => _$WEDNESDAY;
  DayOfWeek get THURSDAY => _$THURSDAY;
  DayOfWeek get FRIDAY => _$FRIDAY;
  DayOfWeek get SATURDAY => _$SATURDAY;
  DayOfWeek get SUNDAY => _$SUNDAY;
  DayOfWeek get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  DayOfWeek valueOf(String name) => _$valueOf(name);
  BuiltSet<DayOfWeek> get values => _$values;
}

abstract class _$DayOfWeekMixin {
  // ignore: non_constant_identifier_names
  _$DayOfWeekMeta get DayOfWeek => const _$DayOfWeekMeta();
}

Serializer<DayOfWeek> _$dayOfWeekSerializer = _$DayOfWeekSerializer();

class _$DayOfWeekSerializer implements PrimitiveSerializer<DayOfWeek> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'MONDAY': 'MONDAY',
    'TUESDAY': 'TUESDAY',
    'WEDNESDAY': 'WEDNESDAY',
    'THURSDAY': 'THURSDAY',
    'FRIDAY': 'FRIDAY',
    'SATURDAY': 'SATURDAY',
    'SUNDAY': 'SUNDAY',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'MONDAY': 'MONDAY',
    'TUESDAY': 'TUESDAY',
    'WEDNESDAY': 'WEDNESDAY',
    'THURSDAY': 'THURSDAY',
    'FRIDAY': 'FRIDAY',
    'SATURDAY': 'SATURDAY',
    'SUNDAY': 'SUNDAY',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[DayOfWeek];
  @override
  final String wireName = 'DayOfWeek';

  @override
  Object serialize(Serializers serializers, DayOfWeek object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  DayOfWeek deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      DayOfWeek.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
