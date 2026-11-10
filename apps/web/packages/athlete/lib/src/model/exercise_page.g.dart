// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExercisePage extends ExercisePage {
  @override
  final BuiltList<Exercise> items;
  @override
  final PageMeta page;

  factory _$ExercisePage([void Function(ExercisePageBuilder)? updates]) =>
      (ExercisePageBuilder()..update(updates))._build();

  _$ExercisePage._({required this.items, required this.page}) : super._();
  @override
  ExercisePage rebuild(void Function(ExercisePageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExercisePageBuilder toBuilder() => ExercisePageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExercisePage && items == other.items && page == other.page;
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
    return (newBuiltValueToStringHelper(r'ExercisePage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class ExercisePageBuilder
    implements Builder<ExercisePage, ExercisePageBuilder> {
  _$ExercisePage? _$v;

  ListBuilder<Exercise>? _items;
  ListBuilder<Exercise> get items => _$this._items ??= ListBuilder<Exercise>();
  set items(ListBuilder<Exercise>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  ExercisePageBuilder() {
    ExercisePage._defaults(this);
  }

  ExercisePageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExercisePage other) {
    _$v = other as _$ExercisePage;
  }

  @override
  void update(void Function(ExercisePageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExercisePage build() => _build();

  _$ExercisePage _build() {
    _$ExercisePage _$result;
    try {
      _$result = _$v ??
          _$ExercisePage._(
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
            r'ExercisePage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
