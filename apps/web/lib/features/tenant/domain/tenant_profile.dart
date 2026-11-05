class TenantProfile {
  const TenantProfile({
    required this.id,
    required this.name,
    required this.defaultLocaleCode,
    required this.hasLogo,
    this.timezone,
  });

  final String id;
  final String name;
  final String defaultLocaleCode;
  final bool hasLogo;

  /// IANA zone of the academy (null when unknown).
  final String? timezone;
}
