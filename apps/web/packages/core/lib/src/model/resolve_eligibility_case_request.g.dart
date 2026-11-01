// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resolve_eligibility_case_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResolveEligibilityCaseRequest extends ResolveEligibilityCaseRequest {
  @override
  final EligibilityCaseResolution resolution;
  @override
  final String? targetTeamId;
  @override
  final String? note;

  factory _$ResolveEligibilityCaseRequest(
          [void Function(ResolveEligibilityCaseRequestBuilder)? updates]) =>
      (ResolveEligibilityCaseRequestBuilder()..update(updates))._build();

  _$ResolveEligibilityCaseRequest._(
      {required this.resolution, this.targetTeamId, this.note})
      : super._();
  @override
  ResolveEligibilityCaseRequest rebuild(
          void Function(ResolveEligibilityCaseRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResolveEligibilityCaseRequestBuilder toBuilder() =>
      ResolveEligibilityCaseRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResolveEligibilityCaseRequest &&
        resolution == other.resolution &&
        targetTeamId == other.targetTeamId &&
        note == other.note;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, resolution.hashCode);
    _$hash = $jc(_$hash, targetTeamId.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResolveEligibilityCaseRequest')
          ..add('resolution', resolution)
          ..add('targetTeamId', targetTeamId)
          ..add('note', note))
        .toString();
  }
}

class ResolveEligibilityCaseRequestBuilder
    implements
        Builder<ResolveEligibilityCaseRequest,
            ResolveEligibilityCaseRequestBuilder> {
  _$ResolveEligibilityCaseRequest? _$v;

  EligibilityCaseResolution? _resolution;
  EligibilityCaseResolution? get resolution => _$this._resolution;
  set resolution(EligibilityCaseResolution? resolution) =>
      _$this._resolution = resolution;

  String? _targetTeamId;
  String? get targetTeamId => _$this._targetTeamId;
  set targetTeamId(String? targetTeamId) => _$this._targetTeamId = targetTeamId;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  ResolveEligibilityCaseRequestBuilder() {
    ResolveEligibilityCaseRequest._defaults(this);
  }

  ResolveEligibilityCaseRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _resolution = $v.resolution;
      _targetTeamId = $v.targetTeamId;
      _note = $v.note;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResolveEligibilityCaseRequest other) {
    _$v = other as _$ResolveEligibilityCaseRequest;
  }

  @override
  void update(void Function(ResolveEligibilityCaseRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResolveEligibilityCaseRequest build() => _build();

  _$ResolveEligibilityCaseRequest _build() {
    final _$result = _$v ??
        _$ResolveEligibilityCaseRequest._(
          resolution: BuiltValueNullFieldError.checkNotNull(
              resolution, r'ResolveEligibilityCaseRequest', 'resolution'),
          targetTeamId: targetTeamId,
          note: note,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
