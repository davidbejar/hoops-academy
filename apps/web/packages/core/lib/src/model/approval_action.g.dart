// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_action.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ApprovalAction _$ADD_PLAYER = const ApprovalAction._('ADD_PLAYER');
const ApprovalAction _$WITHDRAW_PLAYER =
    const ApprovalAction._('WITHDRAW_PLAYER');
const ApprovalAction _$unknownDefaultOpenApi =
    const ApprovalAction._('unknownDefaultOpenApi');

ApprovalAction _$valueOf(String name) {
  switch (name) {
    case 'ADD_PLAYER':
      return _$ADD_PLAYER;
    case 'WITHDRAW_PLAYER':
      return _$WITHDRAW_PLAYER;
    case 'unknownDefaultOpenApi':
      return _$unknownDefaultOpenApi;
    default:
      return _$unknownDefaultOpenApi;
  }
}

final BuiltSet<ApprovalAction> _$values =
    BuiltSet<ApprovalAction>(const <ApprovalAction>[
  _$ADD_PLAYER,
  _$WITHDRAW_PLAYER,
  _$unknownDefaultOpenApi,
]);

class _$ApprovalActionMeta {
  const _$ApprovalActionMeta();
  ApprovalAction get ADD_PLAYER => _$ADD_PLAYER;
  ApprovalAction get WITHDRAW_PLAYER => _$WITHDRAW_PLAYER;
  ApprovalAction get unknownDefaultOpenApi => _$unknownDefaultOpenApi;
  ApprovalAction valueOf(String name) => _$valueOf(name);
  BuiltSet<ApprovalAction> get values => _$values;
}

abstract class _$ApprovalActionMixin {
  // ignore: non_constant_identifier_names
  _$ApprovalActionMeta get ApprovalAction => const _$ApprovalActionMeta();
}

Serializer<ApprovalAction> _$approvalActionSerializer =
    _$ApprovalActionSerializer();

class _$ApprovalActionSerializer
    implements PrimitiveSerializer<ApprovalAction> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ADD_PLAYER': 'ADD_PLAYER',
    'WITHDRAW_PLAYER': 'WITHDRAW_PLAYER',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ADD_PLAYER': 'ADD_PLAYER',
    'WITHDRAW_PLAYER': 'WITHDRAW_PLAYER',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[ApprovalAction];
  @override
  final String wireName = 'ApprovalAction';

  @override
  Object serialize(Serializers serializers, ApprovalAction object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ApprovalAction deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ApprovalAction.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
