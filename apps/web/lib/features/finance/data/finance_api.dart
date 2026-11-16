/// The generated finance client (`hoops_finance_api`). Import it with a prefix
/// (`as fin`): its model names overlap with the core package.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../../../core/http/dio_provider.dart';

/// Generated client on the app's shared [Dio] (its own interceptors are off).
final financeApiProvider = Provider<fin.HoopsFinanceApi>(
  (ref) =>
      fin.HoopsFinanceApi(dio: ref.watch(dioProvider), interceptors: const []),
);
