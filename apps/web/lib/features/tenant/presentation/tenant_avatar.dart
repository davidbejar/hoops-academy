import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  static String initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.single
          .substring(0, words.single.length.clamp(1, 2))
          .toUpperCase();
    }
    return (words.first[0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final logo = showLogo ? ref.watch(tenantLogoProvider).value : null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      foregroundImage: logo == null ? null : MemoryImage(logo),
      child: Text(
        initials(name),
        style: TextStyle(fontSize: radius * 0.75, fontWeight: FontWeight.w600),
      ),
    );
  }
}
