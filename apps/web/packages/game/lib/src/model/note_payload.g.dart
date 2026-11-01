// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotePayload extends NotePayload {
  @override
  final String text;

  factory _$NotePayload([void Function(NotePayloadBuilder)? updates]) =>
      (NotePayloadBuilder()..update(updates))._build();

  _$NotePayload._({required this.text}) : super._();
  @override
  NotePayload rebuild(void Function(NotePayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotePayloadBuilder toBuilder() => NotePayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotePayload && text == other.text;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, text.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotePayload')..add('text', text))
        .toString();
  }
}

class NotePayloadBuilder implements Builder<NotePayload, NotePayloadBuilder> {
  _$NotePayload? _$v;

  String? _text;
  String? get text => _$this._text;
  set text(String? text) => _$this._text = text;

  NotePayloadBuilder() {
    NotePayload._defaults(this);
  }

  NotePayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _text = $v.text;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotePayload other) {
    _$v = other as _$NotePayload;
  }

  @override
  void update(void Function(NotePayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotePayload build() => _build();

  _$NotePayload _build() {
    final _$result = _$v ??
        _$NotePayload._(
          text: BuiltValueNullFieldError.checkNotNull(
              text, r'NotePayload', 'text'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
