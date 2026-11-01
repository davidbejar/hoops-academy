// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_guardian_link_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateGuardianLinkRequest extends CreateGuardianLinkRequest {
  @override
  final String guardianPersonId;
  @override
  final String playerId;

  factory _$CreateGuardianLinkRequest(
          [void Function(CreateGuardianLinkRequestBuilder)? updates]) =>
      (CreateGuardianLinkRequestBuilder()..update(updates))._build();

  _$CreateGuardianLinkRequest._(
      {required this.guardianPersonId, required this.playerId})
      : super._();
  @override
  CreateGuardianLinkRequest rebuild(
          void Function(CreateGuardianLinkRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateGuardianLinkRequestBuilder toBuilder() =>
      CreateGuardianLinkRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateGuardianLinkRequest &&
        guardianPersonId == other.guardianPersonId &&
        playerId == other.playerId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, guardianPersonId.hashCode);
    _$hash = $jc(_$hash, playerId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateGuardianLinkRequest')
          ..add('guardianPersonId', guardianPersonId)
          ..add('playerId', playerId))
        .toString();
  }
}

class CreateGuardianLinkRequestBuilder
    implements
        Builder<CreateGuardianLinkRequest, CreateGuardianLinkRequestBuilder> {
  _$CreateGuardianLinkRequest? _$v;

  String? _guardianPersonId;
  String? get guardianPersonId => _$this._guardianPersonId;
  set guardianPersonId(String? guardianPersonId) =>
      _$this._guardianPersonId = guardianPersonId;

  String? _playerId;
  String? get playerId => _$this._playerId;
  set playerId(String? playerId) => _$this._playerId = playerId;

  CreateGuardianLinkRequestBuilder() {
    CreateGuardianLinkRequest._defaults(this);
  }

  CreateGuardianLinkRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _guardianPersonId = $v.guardianPersonId;
      _playerId = $v.playerId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateGuardianLinkRequest other) {
    _$v = other as _$CreateGuardianLinkRequest;
  }

  @override
  void update(void Function(CreateGuardianLinkRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateGuardianLinkRequest build() => _build();

  _$CreateGuardianLinkRequest _build() {
    final _$result = _$v ??
        _$CreateGuardianLinkRequest._(
          guardianPersonId: BuiltValueNullFieldError.checkNotNull(
              guardianPersonId,
              r'CreateGuardianLinkRequest',
              'guardianPersonId'),
          playerId: BuiltValueNullFieldError.checkNotNull(
              playerId, r'CreateGuardianLinkRequest', 'playerId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
