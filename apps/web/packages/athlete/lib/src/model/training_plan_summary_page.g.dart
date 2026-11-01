// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_plan_summary_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TrainingPlanSummaryPage extends TrainingPlanSummaryPage {
  @override
  final BuiltList<TrainingPlanSummary> items;
  @override
  final PageMeta page;

  factory _$TrainingPlanSummaryPage(
          [void Function(TrainingPlanSummaryPageBuilder)? updates]) =>
      (TrainingPlanSummaryPageBuilder()..update(updates))._build();

  _$TrainingPlanSummaryPage._({required this.items, required this.page})
      : super._();
  @override
  TrainingPlanSummaryPage rebuild(
          void Function(TrainingPlanSummaryPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrainingPlanSummaryPageBuilder toBuilder() =>
      TrainingPlanSummaryPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrainingPlanSummaryPage &&
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
    return (newBuiltValueToStringHelper(r'TrainingPlanSummaryPage')
          ..add('items', items)
          ..add('page', page))
        .toString();
  }
}

class TrainingPlanSummaryPageBuilder
    implements
        Builder<TrainingPlanSummaryPage, TrainingPlanSummaryPageBuilder> {
  _$TrainingPlanSummaryPage? _$v;

  ListBuilder<TrainingPlanSummary>? _items;
  ListBuilder<TrainingPlanSummary> get items =>
      _$this._items ??= ListBuilder<TrainingPlanSummary>();
  set items(ListBuilder<TrainingPlanSummary>? items) => _$this._items = items;

  PageMetaBuilder? _page;
  PageMetaBuilder get page => _$this._page ??= PageMetaBuilder();
  set page(PageMetaBuilder? page) => _$this._page = page;

  TrainingPlanSummaryPageBuilder() {
    TrainingPlanSummaryPage._defaults(this);
  }

  TrainingPlanSummaryPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrainingPlanSummaryPage other) {
    _$v = other as _$TrainingPlanSummaryPage;
  }

  @override
  void update(void Function(TrainingPlanSummaryPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrainingPlanSummaryPage build() => _build();

  _$TrainingPlanSummaryPage _build() {
    _$TrainingPlanSummaryPage _$result;
    try {
      _$result = _$v ??
          _$TrainingPlanSummaryPage._(
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
            r'TrainingPlanSummaryPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
