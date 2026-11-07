// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_academy_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AcceptAcademyRequest extends AcceptAcademyRequest {
  @override
  final String slug;
  @override
  final String timezone;
  @override
  final Locale defaultLocale;
  @override
  final AcceptedAdmin firstAdmin;

  factory _$AcceptAcademyRequest(
          [void Function(AcceptAcademyRequestBuilder)? updates]) =>
      (AcceptAcademyRequestBuilder()..update(updates))._build();

  _$AcceptAcademyRequest._(
      {required this.slug,
      required this.timezone,
      required this.defaultLocale,
      required this.firstAdmin})
      : super._();
  @override
  AcceptAcademyRequest rebuild(
          void Function(AcceptAcademyRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AcceptAcademyRequestBuilder toBuilder() =>
      AcceptAcademyRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcceptAcademyRequest &&
        slug == other.slug &&
        timezone == other.timezone &&
        defaultLocale == other.defaultLocale &&
        firstAdmin == other.firstAdmin;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, defaultLocale.hashCode);
    _$hash = $jc(_$hash, firstAdmin.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AcceptAcademyRequest')
          ..add('slug', slug)
          ..add('timezone', timezone)
          ..add('defaultLocale', defaultLocale)
          ..add('firstAdmin', firstAdmin))
        .toString();
  }
}

class AcceptAcademyRequestBuilder
    implements Builder<AcceptAcademyRequest, AcceptAcademyRequestBuilder> {
  _$AcceptAcademyRequest? _$v;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  Locale? _defaultLocale;
  Locale? get defaultLocale => _$this._defaultLocale;
  set defaultLocale(Locale? defaultLocale) =>
      _$this._defaultLocale = defaultLocale;

  AcceptedAdminBuilder? _firstAdmin;
  AcceptedAdminBuilder get firstAdmin =>
      _$this._firstAdmin ??= AcceptedAdminBuilder();
  set firstAdmin(AcceptedAdminBuilder? firstAdmin) =>
      _$this._firstAdmin = firstAdmin;

  AcceptAcademyRequestBuilder() {
    AcceptAcademyRequest._defaults(this);
  }

  AcceptAcademyRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _slug = $v.slug;
      _timezone = $v.timezone;
      _defaultLocale = $v.defaultLocale;
      _firstAdmin = $v.firstAdmin.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcceptAcademyRequest other) {
    _$v = other as _$AcceptAcademyRequest;
  }

  @override
  void update(void Function(AcceptAcademyRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcceptAcademyRequest build() => _build();

  _$AcceptAcademyRequest _build() {
    _$AcceptAcademyRequest _$result;
    try {
      _$result = _$v ??
          _$AcceptAcademyRequest._(
            slug: BuiltValueNullFieldError.checkNotNull(
                slug, r'AcceptAcademyRequest', 'slug'),
            timezone: BuiltValueNullFieldError.checkNotNull(
                timezone, r'AcceptAcademyRequest', 'timezone'),
            defaultLocale: BuiltValueNullFieldError.checkNotNull(
                defaultLocale, r'AcceptAcademyRequest', 'defaultLocale'),
            firstAdmin: firstAdmin.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'firstAdmin';
        firstAdmin.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'AcceptAcademyRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
