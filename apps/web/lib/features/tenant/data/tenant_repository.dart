import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hoops_core_api/hoops_core_api.dart' as api;

import '../../../core/errors/app_error.dart';
import '../domain/tenant_profile.dart';

abstract class TenantRepository {
  Future<TenantProfile> profile(String tenantId);

  /// Logo bytes, or null when the academy has none (404).
  Future<Uint8List?> logo(String tenantId);
}

class ApiTenantRepository implements TenantRepository {
  ApiTenantRepository(Dio dio)
    : _api = api.HoopsCoreApi(dio: dio, interceptors: const []).getTenantApi();

  final api.TenantApi _api;

  @override
  Future<TenantProfile> profile(String tenantId) async {
    final p = (await _api.getTenantProfile(xTenantId: tenantId)).data!;
    return TenantProfile(
      id: p.id,
      name: p.name,
      defaultLocaleCode: p.defaultLocale.name,
      hasLogo: p.hasLogo,
    );
  }

  @override
  Future<Uint8List?> logo(String tenantId) async {
    try {
      return (await _api.getTenantLogo(xTenantId: tenantId)).data;
    } on DioException catch (e) {
      if (AppError.fromDioException(e).kind == AppErrorKind.notFound) {
        return null;
      }
      rethrow;
    }
  }
}
