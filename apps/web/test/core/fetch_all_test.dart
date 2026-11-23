import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/fetch_all.dart';

/// A server list of [total] numbers, served like the services do: pages of at
/// most 200, `totalPages` from the count (ADR-0061).
class _Server {
  _Server(this.total);
  final int total;
  final List<({int page, int size})> asked = [];

  Future<PageSlice<int>> call(int page, int size) async {
    asked.add((page: page, size: size));
    if (size < 1 || size > 200) throw ArgumentError('size $size');
    final from = (page * size).clamp(0, total);
    final to = (from + size).clamp(0, total);
    return (
      items: [for (var i = from; i < to; i++) i],
      totalPages: (total + size - 1) ~/ size,
    );
  }
}

void main() {
  test('reads every page with the largest size the server accepts', () async {
    final server = _Server(450);
    final all = await fetchAll(server.call);
    expect(all, [for (var i = 0; i < 450; i++) i]);
    expect(server.asked, [
      (page: 0, size: 200),
      (page: 1, size: 200),
      (page: 2, size: 200),
    ]);
  });

  test('one request for a list that fits one page, none extra', () async {
    final server = _Server(3);
    expect(await fetchAll(server.call), [0, 1, 2]);
    expect(server.asked, hasLength(1));
  });

  test('an empty list is one request and no items', () async {
    final server = _Server(0);
    expect(await fetchAll(server.call), isEmpty);
    expect(server.asked, hasLength(1));
  });

  test('stops on an empty page even if the count promised more', () async {
    var calls = 0;
    final all = await fetchAll<int>((page, size) async {
      calls++;
      return (items: page == 0 ? [1, 2] : <int>[], totalPages: 9);
    });
    expect(all, [1, 2]);
    expect(calls, 2);
  });

  test('a list longer than the safety bound fails instead of being cut', () {
    var calls = 0;
    expect(
      fetchAll<int>((page, size) async {
        calls++;
        return (items: List.filled(size, page), totalPages: 1000000);
      }),
      throwsA(isA<ListTooLongError>()),
    );
    addTearDown(() => expect(calls, fetchAllPageLimit));
  });
}
