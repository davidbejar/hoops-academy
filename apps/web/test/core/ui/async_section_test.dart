import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/ui/async_body.dart';

import '../../support/kit_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  AsyncValue<List<int>> value, {
  VoidCallback? onRetry,
  bool Function(AppError error)? hideWhen,
  String? failedLabel,
  bool Function(List<int> data)? isEmpty,
}) => pumpKit(
  tester,
  SizedBox(
    width: 328,
    child: AsyncSection<List<int>>(
      value: value,
      onRetry: onRetry ?? () {},
      hideWhen: hideWhen,
      failedLabel: failedLabel,
      isEmpty: isEmpty,
      emptyMessage: 'Nada aquí',
      loadingKey: const Key('s-loading'),
      errorKey: const Key('s-error'),
      builder: (context, data) => Text('datos ${data.length}'),
    ),
  ),
);

void main() {
  testWidgets('loading: a compact spinner with the key it was given', (
    tester,
  ) async {
    await pumpKit(
      tester,
      SizedBox(
        width: 328,
        child: AsyncSection<List<int>>(
          value: const AsyncLoading(),
          onRetry: () {},
          loadingKey: const Key('s-loading'),
          builder: (context, data) => const Text('datos'),
        ),
      ),
    );
    expect(find.byKey(const Key('s-loading')), findsOneWidget);
    expect(find.text('datos'), findsNothing);
  });

  testWidgets('data: the builder', (tester) async {
    await _pump(tester, const AsyncData([1, 2]));
    expect(find.text('datos 2'), findsOneWidget);
  });

  testWidgets('empty: the message, not the builder', (tester) async {
    await _pump(tester, const AsyncData([]), isEmpty: (d) => d.isEmpty);
    expect(find.text('Nada aquí'), findsOneWidget);
    expect(find.text('datos 0'), findsNothing);
  });

  testWidgets('error: the mapped message, the failed label and a retry', (
    tester,
  ) async {
    var retried = 0;
    await _pump(
      tester,
      AsyncError(
        const AppError(
          kind: AppErrorKind.conflict,
          status: 409,
          code: 'TENANT_WITHDRAWN',
        ),
        StackTrace.empty,
      ),
      onRetry: () => retried++,
      failedLabel: 'No se pudo cargar',
    );
    expect(find.byKey(const Key('s-error')), findsOneWidget);
    expect(find.textContaining('No se pudo cargar · '), findsOneWidget);
    expect(find.textContaining('La academia está retirada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry-button')));
    expect(retried, 1);
  });

  testWidgets('error: a failure the caller hides takes no room', (
    tester,
  ) async {
    await _pump(
      tester,
      AsyncError(
        const AppError(kind: AppErrorKind.forbidden, status: 403),
        StackTrace.empty,
      ),
      hideWhen: (e) => e.kind == AppErrorKind.forbidden,
    );
    expect(find.byKey(const Key('s-error')), findsNothing);
    expect(find.byKey(const Key('retry-button')), findsNothing);
  });

  testWidgets('a refresh that fails keeps showing the data', (tester) async {
    await _pump(
      tester,
      AsyncValue<List<int>>.error(
        const AppError(kind: AppErrorKind.server),
        StackTrace.empty,
      ).copyWithPrevious(const AsyncData([7])),
    );
    expect(find.text('datos 1'), findsOneWidget);
  });
}
