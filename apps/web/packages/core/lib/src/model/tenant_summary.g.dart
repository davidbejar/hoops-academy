// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TenantSummary extends TenantSummary {
  @override
  final String id;
  @override
  final String slug;
  @override
  final String name;
  @override
  final TenantStatus status;
  @override
  final bool hasLogo;

  factory _$TenantSummary([void Function(TenantSummaryBuilder)? updates]) =>
      (TenantSummaryBuilder()..update(updates))._build();

  _$TenantSummary._(
      {required this.id,
      required this.slug,
      required this.name,
      required this.status,
      required this.hasLogo})
      : super._();
  @override
  TenantSummary rebuild(void Function(TenantSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TenantSummaryBuilder toBuilder() => TenantSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TenantSummary &&
        id == other.id &&
        slug == other.slug &&
        name == other.name &&
        status == other.status &&
        hasLogo == other.hasLogo;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, hasLogo.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TenantSummary')
          ..add('id', id)
          ..add('slug', slug)
          ..add('name', name)
          ..add('status', status)
          ..add('hasLogo', hasLogo))
        .toString();
  }
}

class TenantSummaryBuilder
    implements Builder<TenantSummary, TenantSummaryBuilder> {
  _$TenantSummary? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  TenantStatus? _status;
  TenantStatus? get status => _$this._status;
  set status(TenantStatus? status) => _$this._status = status;

  bool? _hasLogo;
  bool? get hasLogo => _$this._hasLogo;
  set hasLogo(bool? hasLogo) => _$this._hasLogo = hasLogo;

  TenantSummaryBuilder() {
    TenantSummary._defaults(this);
  }

  TenantSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _slug = $v.slug;
      _name = $v.name;
      _status = $v.status;
      _hasLogo = $v.hasLogo;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TenantSummary other) {
    _$v = other as _$TenantSummary;
  }

  @override
  void update(void Function(TenantSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TenantSummary build() => _build();

  _$TenantSummary _build() {
    final _$result = _$v ??
        _$TenantSummary._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'TenantSummary', 'id'),
          slug: BuiltValueNullFieldError.checkNotNull(
              slug, r'TenantSummary', 'slug'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'TenantSummary', 'name'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'TenantSummary', 'status'),
          hasLogo: BuiltValueNullFieldError.checkNotNull(
              hasLogo, r'TenantSummary', 'hasLogo'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
