// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_session_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TrainingSessionPage extends TrainingSessionPage {
  @override
  final BuiltList<TrainingSession> items;
  @override
  final PageMeta page;

  factory _$TrainingSessionPage(
          [void Function(TrainingSessionPageBuilder)? updates]) =>
      (TrainingSessionPageBuilder()..update(updates))._build();

  _$TrainingSessionPage._({required this.items, required this.page})
      : super._();
  @override
  TrainingSessionPage rebuild(
          void Function(TrainingSessionPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrainingSessionPageBuilder toBuilder() =>
      TrainingSessionPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrainingSessionPage &&
        items == other.items &&
        page == other.page;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TrainingSessionPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class TrainingSessionPageBuilder
    implements Builder<TrainingSessionPage, TrainingSessionPageBuilder> {
  _$TrainingSessionPage? _$v;

  ListBuilder<TrainingSession>? _items;
  ListBuilder<TrainingSession> get items =>
      _$this._items ??= ListBuilder<TrainingSession>();
  set items(ListBuilder<TrainingSession>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  TrainingSessionPageBuilder() {
    TrainingSessionPage._defaults(this);
  }

  TrainingSessionPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrainingSessionPage other) {
    _$v = other as _$TrainingSessionPage;
  }

  @override
  void update(void Function(TrainingSessionPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrainingSessionPage build() => _build();

  _$TrainingSessionPage _build() {
    _$TrainingSessionPage _$result;
    try {
      _$result = _$v ??
          _$TrainingSessionPage._(
            items: items.build(),
            page: page.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
        _$failedField = 'page';
        page.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TrainingSessionPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
