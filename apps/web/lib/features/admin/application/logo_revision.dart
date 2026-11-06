import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped after every logo change; the app bar logo re-validates against the
/// server when it is above zero (cache busting, see `tenantLogoProvider`).
class LogoRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final logoRevisionProvider = NotifierProvider<LogoRevision, int>(
  LogoRevision.new,
);
