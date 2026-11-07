// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_request_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AcademyRequestStatus _$PENDING = const AcademyRequestStatus._('PENDING');
const AcademyRequestStatus _$ACCEPTED =
    const AcademyRequestStatus._('ACCEPTED');
const AcademyRequestStatus _$REJECTED =
    const AcademyRequestStatus._('REJECTED');
const AcademyRequestStatus _$unknownDefaultOpenApi =
    const AcademyRequestStatus._('unknownDefaultOpenApi');

AcademyRequestStatus _$valueOf(String name) {
  switch (name) {
    case 'PENDING':
      return _$PENDING;
    case 'ACCEPTED':
      return _$ACCEPTED;
    case 'REJECTED':
      return _$REJECTED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<AcademyRequestStatus> _$values =
    BuiltSet<AcademyRequestStatus>(const <AcademyRequestStatus>[
  _$PENDING,
  _$ACCEPTED,
  _$REJECTED,
  _$unknownDefaultOpenApi,
]);

class _$AcademyRequestStatusMeta {
  const _$AcademyRequestStatusMeta();
  AcademyRequestStatus get PENDING => _$PENDING;
  AcademyRequestStatus get ACCEPTED => _$ACCEPTED;
  AcademyRequestStatus get REJECTED => _$REJECTED;
  AcademyRequestStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  AcademyRequestStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<AcademyRequestStatus> get values => _$values;
}

abstract class _$AcademyRequestStatusMixin {
  // ignore: non_constant_identifier_names
  _$AcademyRequestStatusMeta get AcademyRequestStatus =>
      const _$AcademyRequestStatusMeta();
}

Serializer<AcademyRequestStatus> _$academyRequestStatusSerializer =
    _$AcademyRequestStatusSerializer();

class _$AcademyRequestStatusSerializer
    implements PrimitiveSerializer<AcademyRequestStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'PENDING': 'PENDING',
    'ACCEPTED': 'ACCEPTED',
    'REJECTED': 'REJECTED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'PENDING': 'PENDING',
    'ACCEPTED': 'ACCEPTED',
    'REJECTED': 'REJECTED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AcademyRequestStatus];
  @override
  final String wireName = 'AcademyRequestStatus';

  @override
  Object serialize(Serializers serializers, AcademyRequestStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AcademyRequestStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AcademyRequestStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
