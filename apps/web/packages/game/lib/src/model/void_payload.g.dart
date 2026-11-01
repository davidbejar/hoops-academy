// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'void_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VoidPayload extends VoidPayload {
  @override
  final String targetEventId;

  factory _$VoidPayload([void Function(VoidPayloadBuilder)? updates]) =>
      (VoidPayloadBuilder()..update(updates))._build();

  _$VoidPayload._({required this.targetEventId}) : super._();
  @override
  VoidPayload rebuild(void Function(VoidPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VoidPayloadBuilder toBuilder() => VoidPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VoidPayload && targetEventId == other.targetEventId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, targetEventId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VoidPayload')
          ..add('targetEventId', targetEventId))
        .toString();
  }
}

class VoidPayloadBuilder implements Builder<VoidPayload, VoidPayloadBuilder> {
  _$VoidPayload? _$v;

  String? _targetEventId;
  String? get targetEventId => _$this._targetEventId;
  set targetEventId(String? targetEventId) =>
      _$this._targetEventId = targetEventId;

  VoidPayloadBuilder() {
    VoidPayload._defaults(this);
  }

  VoidPayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _targetEventId = $v.targetEventId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VoidPayload other) {
    _$v = other as _$VoidPayload;
  }

  @override
  void update(void Function(VoidPayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VoidPayload build() => _build();

  _$VoidPayload _build() {
    final _$result = _$v ??
        _$VoidPayload._(
          targetEventId: BuiltValueNullFieldError.checkNotNull(
              targetEventId, r'VoidPayload', 'targetEventId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
