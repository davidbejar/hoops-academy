import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Persistent sqlite file in the app's documents directory (non-web builds).
DatabaseConnection openMatchConnection({
  void Function(String storage)? onStorage,
}) {
  onStorage?.call('native');
  return driftDatabase(name: 'hoops_match');
}
