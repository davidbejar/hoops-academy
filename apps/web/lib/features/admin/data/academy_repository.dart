import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/api/api.dart' as api;

/// Academy profile, settings and logo (`/api/core/tenant*`).
abstract class AcademyRepository {
  Future<api.TenantProfile> profile();
  Future<api.TenantSettings> settings();

  /// PATCH profile then PUT settings; returns the stored profile.
  Future<api.TenantProfile> save({
    required api.UpdateTenantProfileRequest profile,
    required api.TenantSettings settings,
  });

  Future<api.TenantLogo> uploadLogo({
    required Uint8List bytes,
    required String mimeType,
    required String fileName,
  });

  Future<void> deleteLogo();
}

class ApiAcademyRepository implements AcademyRepository {
  ApiAcademyRepository(api.HoopsCoreApi client, this._tenantId)
    : _api = client.getTenantApi();

  final api.TenantApi _api;
  final String _tenantId;

  @override
  Future<api.TenantProfile> profile() async =>
      (await _api.getTenantProfile(xTenantId: _tenantId)).data!;

  @override
  Future<api.TenantSettings> settings() async =>
      (await _api.getTenantSettings(xTenantId: _tenantId)).data!;

  @override
  Future<api.TenantProfile> save({
    required api.UpdateTenantProfileRequest profile,
    required api.TenantSettings settings,
  }) async {
    final saved = (await _api.updateTenantProfile(
      xTenantId: _tenantId,
      updateTenantProfileRequest: profile,
    )).data!;
    await _api.replaceTenantSettings(
      xTenantId: _tenantId,
      tenantSettings: settings,
    );
    return saved;
  }

  @override
  Future<api.TenantLogo> uploadLogo({
    required Uint8List bytes,
    required String mimeType,
    required String fileName,
  }) async => (await _api.putTenantLogo(
    xTenantId: _tenantId,
    // Contract gap: the generated method always sends `Content-Type: image/png`
    // (one allowed type per the contract); the server detects the real format
    // from the magic bytes (ADR-0009), so JPEG/WebP bodies are still handled.
    body: MultipartFile.fromBytes(
      bytes,
      filename: fileName,
      contentType: DioMediaType.parse(mimeType),
    ),
  )).data!;

  @override
  Future<void> deleteLogo() async {
    await _api.deleteTenantLogo(xTenantId: _tenantId);
  }
}
