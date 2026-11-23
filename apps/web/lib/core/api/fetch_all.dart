/// Reading a whole list from a paged list operation (ADR-0061).
library;

/// The largest page every list operation accepts (`Size` in `common.yaml`; the services refuse more).
const maxPageSize = 200;

/// Pages [fetchAll] reads at most: 200 × 50 = 10,000 items, far above any academy's list.
const fetchAllPageLimit = 50;

/// One page of a list operation: its items and the server's `PageMeta.totalPages`.
typedef PageSlice<T> = ({Iterable<T> items, int totalPages});

/// A list longer than [fetchAllPageLimit] pages: refused rather than shown cut.
class ListTooLongError extends Error {
  @override
  String toString() =>
      'ListTooLongError: more than ${fetchAllPageLimit * maxPageSize} items';
}

/// Every item of a paged list operation, for a screen that shows the list whole. [fetchPage] calls the operation
/// for one 0-based page of `size` items; pages are read in order until the server's last page (or an empty one).
Future<List<T>> fetchAll<T>(
  Future<PageSlice<T>> Function(int page, int size) fetchPage,
) async {
  final all = <T>[];
  for (var page = 0; page < fetchAllPageLimit; page++) {
    final slice = await fetchPage(page, maxPageSize);
    all.addAll(slice.items);
    if (slice.items.isEmpty || page + 1 >= slice.totalPages) return all;
  }
  throw ListTooLongError();
}
