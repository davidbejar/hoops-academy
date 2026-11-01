class TenantProfile {
  const TenantProfile({
    required this.id,
    required this.name,
    required this.defaultLocaleCode,
    required this.hasLogo,
  });

  final String id;
  final String name;
  final String defaultLocaleCode;
  final bool hasLogo;
}
