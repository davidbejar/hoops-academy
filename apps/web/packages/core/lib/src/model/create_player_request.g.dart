// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_player_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreatePlayerRequest extends CreatePlayerRequest {
  @override
  final String givenName;
  @override
  final String familyName;
  @override
  final Date birthDate;
  @override
  final Gender gender;
  @override
  final String? email;
  @override
  final String? teamId;
  @override
  final String? jerseyNumber;
  @override
  final String? note;

  factory _$CreatePlayerRequest(
          [void Function(CreatePlayerRequestBuilder)? updates]) =>
      (CreatePlayerRequestBuilder()..update(updates))._build();

  _$CreatePlayerRequest._(
      {required this.givenName,
      required this.familyName,
      required this.birthDate,
      required this.gender,
      this.email,
      this.teamId,
      this.jerseyNumber,
      this.note})
      : super._();
  @override
  CreatePlayerRequest rebuild(
          void Function(CreatePlayerRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreatePlayerRequestBuilder toBuilder() =>
      CreatePlayerRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreatePlayerRequest &&
        givenName == other.givenName &&
        familyName == other.familyName &&
        birthDate == other.birthDate &&
        gender == other.gender &&
        email == other.email &&
        teamId == other.teamId &&
        jerseyNumber == other.jerseyNumber &&
        note == other.note;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, givenName.hashCode);
    _$hash = $jc(_$hash, familyName.hashCode);
    _$hash = $jc(_$hash, birthDate.hashCode);
    _$hash = $jc(_$hash, gender.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, teamId.hashCode);
    _$hash = $jc(_$hash, jerseyNumber.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreatePlayerRequest')
          ..add('givenName', givenName)
          ..add('familyName', familyName)
          ..add('birthDate', birthDate)
          ..add('gender', gender)
          ..add('email', email)
          ..add('teamId', teamId)
          ..add('jerseyNumber', jerseyNumber)
          ..add('note', note))
        .toString();
  }
}

class CreatePlayerRequestBuilder
    implements Builder<CreatePlayerRequest, CreatePlayerRequestBuilder> {
  _$CreatePlayerRequest? _$v;

  String? _givenName;
  String? get givenName => _$this._givenName;
  set givenName(String? givenName) => _$this._givenName = givenName;

  String? _familyName;
  String? get familyName => _$this._familyName;
  set familyName(String? familyName) => _$this._familyName = familyName;

  Date? _birthDate;
  Date? get birthDate => _$this._birthDate;
  set birthDate(Date? birthDate) => _$this._birthDate = birthDate;

  Gender? _gender;
  Gender? get gender => _$this._gender;
  set gender(Gender? gender) => _$this._gender = gender;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _teamId;
  String? get teamId => _$this._teamId;
  set teamId(String? teamId) => _$this._teamId = teamId;

  String? _jerseyNumber;
  String? get jerseyNumber => _$this._jerseyNumber;
  set jerseyNumber(String? jerseyNumber) => _$this._jerseyNumber = jerseyNumber;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  CreatePlayerRequestBuilder() {
    CreatePlayerRequest._defaults(this);
  }

  CreatePlayerRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _givenName = $v.givenName;
      _familyName = $v.familyName;
      _birthDate = $v.birthDate;
      _gender = $v.gender;
      _email = $v.email;
      _teamId = $v.teamId;
      _jerseyNumber = $v.jerseyNumber;
      _note = $v.note;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreatePlayerRequest other) {
    _$v = other as _$CreatePlayerRequest;
  }

  @override
  void update(void Function(CreatePlayerRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreatePlayerRequest build() => _build();

  _$CreatePlayerRequest _build() {
    final _$result = _$v ??
        _$CreatePlayerRequest._(
          givenName: BuiltValueNullFieldError.checkNotNull(
              givenName, r'CreatePlayerRequest', 'givenName'),
          familyName: BuiltValueNullFieldError.checkNotNull(
              familyName, r'CreatePlayerRequest', 'familyName'),
          birthDate: BuiltValueNullFieldError.checkNotNull(
              birthDate, r'CreatePlayerRequest', 'birthDate'),
          gender: BuiltValueNullFieldError.checkNotNull(
              gender, r'CreatePlayerRequest', 'gender'),
          email: email,
          teamId: teamId,
          jerseyNumber: jerseyNumber,
          note: note,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
