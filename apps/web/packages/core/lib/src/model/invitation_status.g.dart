// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const InvitationStatus _$NONE = const InvitationStatus._('NONE');
const InvitationStatus _$PENDING = const InvitationStatus._('PENDING');
const InvitationStatus _$ACCEPTED = const InvitationStatus._('ACCEPTED');
const InvitationStatus _$unknownDefaultOpenApi =
    const InvitationStatus._('unknownDefaultOpenApi');

InvitationStatus _$valueOf(String name) {
  switch (name) {
    case 'NONE':
      return _$NONE;
    case 'PENDING':
      return _$PENDING;
    case 'ACCEPTED':
      return _$ACCEPTED;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<InvitationStatus> _$values =
    BuiltSet<InvitationStatus>(const <InvitationStatus>[
  _$NONE,
  _$PENDING,
  _$ACCEPTED,
  _$unknownDefaultOpenApi,
]);

class _$InvitationStatusMeta {
  const _$InvitationStatusMeta();
  InvitationStatus get NONE => _$NONE;
  InvitationStatus get PENDING => _$PENDING;
  InvitationStatus get ACCEPTED => _$ACCEPTED;
  InvitationStatus get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  InvitationStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<InvitationStatus> get values => _$values;
}

abstract class _$InvitationStatusMixin {
  // ignore: non_constant_identifier_names
  _$InvitationStatusMeta get InvitationStatus => const _$InvitationStatusMeta();
}

Serializer<InvitationStatus> _$invitationStatusSerializer =
    _$InvitationStatusSerializer();

class _$InvitationStatusSerializer
    implements PrimitiveSerializer<InvitationStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'NONE': 'NONE',
    'PENDING': 'PENDING',
    'ACCEPTED': 'ACCEPTED',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'NONE': 'NONE',
    'PENDING': 'PENDING',
    'ACCEPTED': 'ACCEPTED',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[InvitationStatus];
  @override
  final String wireName = 'InvitationStatus';

  @override
  Object serialize(Serializers serializers, InvitationStatus object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  InvitationStatus deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      InvitationStatus.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
