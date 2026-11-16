import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

const _keep = Object();

/// The filters and the page of the expenses list (`GET /api/finance/expenses`):
/// the days bound `spentOn`, both ends included.
class ExpenseQuery {
  const ExpenseQuery({
    this.from,
    this.to,
    this.category,
    this.page = 0,
    this.size = defaultSize,
  });

  static const defaultSize = 25;

  final fin.Date? from;
  final fin.Date? to;
  final fin.ExpenseCategory? category;
  final int page;
  final int size;

  bool get hasFilter => from != null || to != null || category != null;

  /// A copy with the given values; pass `null` to clear a filter. Changing a
  /// filter goes back to the first page unless [page] is given.
  ExpenseQuery copyWith({
    Object? from = _keep,
    Object? to = _keep,
    Object? category = _keep,
    int? page,
  }) {
    final filtered = from != _keep || to != _keep || category != _keep;
    return ExpenseQuery(
      from: identical(from, _keep) ? this.from : from as fin.Date?,
      to: identical(to, _keep) ? this.to : to as fin.Date?,
      category: identical(category, _keep)
          ? this.category
          : category as fin.ExpenseCategory?,
      page: page ?? (filtered ? 0 : this.page),
      size: size,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExpenseQuery &&
      other.from == from &&
      other.to == to &&
      other.category == category &&
      other.page == page &&
      other.size == size;

  @override
  int get hashCode => Object.hash(from, to, category, page, size);
}
