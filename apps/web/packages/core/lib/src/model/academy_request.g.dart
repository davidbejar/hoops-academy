// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AcademyRequest extends AcademyRequest {
  @override
  final String id;
  @override
  final AcademyRequestStatus status;
  @override
  final String? name;
  @override
  final String email;
  @override
  final AcademyRequestRole role;
  @override
  final String academyName;
  @override
  final Locale locale;
  @override
  final DateTime requestedAt;
  @override
  final DateTime? decidedAt;
  @override
  final String? decidedBy;
  @override
  final String? reason;
  @override
  final String? tenantId;
  @override
  final DateTime? notifiedAt;

  factory _$AcademyRequest([void Function(AcademyRequestBuilder)? updates]) =>
      (AcademyRequestBuilder()..update(updates))._build();

  _$AcademyRequest._(
      {required this.id,
      required this.status,
      this.name,
      required this.email,
      required this.role,
      required this.academyName,
      required this.locale,
      required this.requestedAt,
      this.decidedAt,
      this.decidedBy,
      this.reason,
      this.tenantId,
      this.notifiedAt})
      : super._();
  @override
  AcademyRequest rebuild(void Function(AcademyRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AcademyRequestBuilder toBuilder() => AcademyRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcademyRequest &&
        id == other.id &&
        status == other.status &&
        name == other.name &&
        email == other.email &&
        role == other.role &&
        academyName == other.academyName &&
        locale == other.locale &&
        requestedAt == other.requestedAt &&
        decidedAt == other.decidedAt &&
        decidedBy == other.decidedBy &&
        reason == other.reason &&
        tenantId == other.tenantId &&
        notifiedAt == other.notifiedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, academyName.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, requestedAt.hashCode);
    _$hash = $jc(_$hash, decidedAt.hashCode);
    _$hash = $jc(_$hash, decidedBy.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, tenantId.hashCode);
    _$hash = $jc(_$hash, notifiedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AcademyRequest')
          ..add('id', id)
          ..add('status', status)
          ..add('name', name)
          ..add('email', email)
          ..add('role', role)
          ..add('academyName', academyName)
          ..add('locale', locale)
          ..add('requestedAt', requestedAt)
          ..add('decidedAt', decidedAt)
          ..add('decidedBy', decidedBy)
          ..add('reason', reason)
          ..add('tenantId', tenantId)
          ..add('notifiedAt', notifiedAt))
        .toString();
  }
}

class AcademyRequestBuilder
    implements Builder<AcademyRequest, AcademyRequestBuilder> {
  _$AcademyRequest? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  AcademyRequestStatus? _status;
  AcademyRequestStatus? get status => _$this._status;
  set status(AcademyRequestStatus? status) => _$this._status = status;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  AcademyRequestRole? _role;
  AcademyRequestRole? get role => _$this._role;
  set role(AcademyRequestRole? role) => _$this._role = role;

  String? _academyName;
  String? get academyName => _$this._academyName;
  set academyName(String? academyName) => _$this._academyName = academyName;

  Locale? _locale;
  Locale? get locale => _$this._locale;
  set locale(Locale? locale) => _$this._locale = locale;

  DateTime? _requestedAt;
  DateTime? get requestedAt => _$this._requestedAt;
  set requestedAt(DateTime? requestedAt) => _$this._requestedAt = requestedAt;

  DateTime? _decidedAt;
  DateTime? get decidedAt => _$this._decidedAt;
  set decidedAt(DateTime? decidedAt) => _$this._decidedAt = decidedAt;

  String? _decidedBy;
  String? get decidedBy => _$this._decidedBy;
  set decidedBy(String? decidedBy) => _$this._decidedBy = decidedBy;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  String? _tenantId;
  String? get tenantId => _$this._tenantId;
  set tenantId(String? tenantId) => _$this._tenantId = tenantId;

  DateTime? _notifiedAt;
  DateTime? get notifiedAt => _$this._notifiedAt;
  set notifiedAt(DateTime? notifiedAt) => _$this._notifiedAt = notifiedAt;

  AcademyRequestBuilder() {
    AcademyRequest._defaults(this);
  }

  AcademyRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _status = $v.status;
      _name = $v.name;
      _email = $v.email;
      _role = $v.role;
      _academyName = $v.academyName;
      _locale = $v.locale;
      _requestedAt = $v.requestedAt;
      _decidedAt = $v.decidedAt;
      _decidedBy = $v.decidedBy;
      _reason = $v.reason;
      _tenantId = $v.tenantId;
      _notifiedAt = $v.notifiedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcademyRequest other) {
    _$v = other as _$AcademyRequest;
  }

  @override
  void update(void Function(AcademyRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcademyRequest build() => _build();

  _$AcademyRequest _build() {
    final _$result = _$v ??
        _$AcademyRequest._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'AcademyRequest', 'id'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'AcademyRequest', 'status'),
          name: name,
          email: BuiltValueNullFieldError.checkNotNull(
              email, r'AcademyRequest', 'email'),
          role: BuiltValueNullFieldError.checkNotNull(
              role, r'AcademyRequest', 'role'),
          academyName: BuiltValueNullFieldError.checkNotNull(
              academyName, r'AcademyRequest', 'academyName'),
          locale: BuiltValueNullFieldError.checkNotNull(
              locale, r'AcademyRequest', 'locale'),
          requestedAt: BuiltValueNullFieldError.checkNotNull(
              requestedAt, r'AcademyRequest', 'requestedAt'),
          decidedAt: decidedAt,
          decidedBy: decidedBy,
          reason: reason,
          tenantId: tenantId,
          notifiedAt: notifiedAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
