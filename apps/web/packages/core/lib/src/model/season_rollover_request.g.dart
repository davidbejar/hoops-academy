// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_rollover_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SeasonRolloverRequest extends SeasonRolloverRequest {
  @override
  final String fromSeasonId;
  @override
  final bool? cloneStaff;
  @override
  final bool? clonePlayers;

  factory _$SeasonRolloverRequest(
          [void Function(SeasonRolloverRequestBuilder)? updates]) =>
      (SeasonRolloverRequestBuilder()..update(updates))._build();

  _$SeasonRolloverRequest._(
      {required this.fromSeasonId, this.cloneStaff, this.clonePlayers})
      : super._();
  @override
  SeasonRolloverRequest rebuild(
          void Function(SeasonRolloverRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SeasonRolloverRequestBuilder toBuilder() =>
      SeasonRolloverRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SeasonRolloverRequest &&
        fromSeasonId == other.fromSeasonId &&
        cloneStaff == other.cloneStaff &&
        clonePlayers == other.clonePlayers;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fromSeasonId.hashCode);
    _$hash = $jc(_$hash, cloneStaff.hashCode);
    _$hash = $jc(_$hash, clonePlayers.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SeasonRolloverRequest')
          ..add('fromSeasonId', fromSeasonId)
          ..add('cloneStaff', cloneStaff)
          ..add('clonePlayers', clonePlayers))
        .toString();
  }
}

class SeasonRolloverRequestBuilder
    implements Builder<SeasonRolloverRequest, SeasonRolloverRequestBuilder> {
  _$SeasonRolloverRequest? _$v;

  String? _fromSeasonId;
  String? get fromSeasonId => _$this._fromSeasonId;
  set fromSeasonId(String? fromSeasonId) => _$this._fromSeasonId = fromSeasonId;

  bool? _cloneStaff;
  bool? get cloneStaff => _$this._cloneStaff;
  set cloneStaff(bool? cloneStaff) => _$this._cloneStaff = cloneStaff;

  bool? _clonePlayers;
  bool? get clonePlayers => _$this._clonePlayers;
  set clonePlayers(bool? clonePlayers) => _$this._clonePlayers = clonePlayers;

  SeasonRolloverRequestBuilder() {
    SeasonRolloverRequest._defaults(this);
  }

  SeasonRolloverRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fromSeasonId = $v.fromSeasonId;
      _cloneStaff = $v.cloneStaff;
      _clonePlayers = $v.clonePlayers;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SeasonRolloverRequest other) {
    _$v = other as _$SeasonRolloverRequest;
  }

  @override
  void update(void Function(SeasonRolloverRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SeasonRolloverRequest build() => _build();

  _$SeasonRolloverRequest _build() {
    final _$result = _$v ??
        _$SeasonRolloverRequest._(
          fromSeasonId: BuiltValueNullFieldError.checkNotNull(
              fromSeasonId, r'SeasonRolloverRequest', 'fromSeasonId'),
          cloneStaff: cloneStaff,
          clonePlayers: clonePlayers,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
