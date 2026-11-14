import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/kit.dart';
import '../application/tenant_providers.dart';

/// Academy logo, falling back to the initials of its name (also while
/// loading and when the academy has no logo / the request 404s).
class TenantAvatar extends ConsumerWidget {
  const TenantAvatar({
    super.key,
    required this.name,
    this.showLogo = true,
    this.radius = 16,
  });

  final String name;
  final bool showLogo;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logo = showLogo ? ref.watch(tenantLogoProvider).value : null;
    return InitialsAvatar(
      name: name,
      size: radius * 2,
      image: logo == null ? null : MemoryImage(logo),
    );
  }
}
