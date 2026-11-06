import '../../../core/api/api.dart' as api;
import '../../../core/api/clear_list.dart';

/// Age categories (`/api/core/age-categories`).
abstract class AgeCategoriesRepository {
  Future<List<api.AgeCategory>> list();
  Future<api.AgeCategory> create({
    required String code,
    required String name,
    int? maxAge,
    required int rank,
  });

  /// A null [maxAge] makes the category senior (no limit): `maxAge` is named in `clear` (ADR-0032).
  Future<api.AgeCategory> update(
    String id, {
    required String code,
    required String name,
    int? maxAge,
    required int rank,
  });
  Future<void> delete(String id);
}

class ApiAgeCategoriesRepository implements AgeCategoriesRepository {
  ApiAgeCategoriesRepository(api.HoopsCoreApi client, this._t)
    : _api = client.getAgeCategoriesApi();

  final api.AgeCategoriesApi _api;
  final String _t;

  @override
  Future<List<api.AgeCategory>> list() async =>
      (await _api.listAgeCategories(xTenantId: _t)).data!.toList();

  @override
  Future<api.AgeCategory> create({
    required String code,
    required String name,
    int? maxAge,
    required int rank,
  }) async => (await _api.createAgeCategory(
    xTenantId: _t,
    ageCategoryInput: api.AgeCategoryInput(
      (b) => b
        ..code = code
        ..name = name
        ..maxAge = maxAge
        ..rank = rank,
    ),
  )).data!;

  @override
  Future<api.AgeCategory> update(
    String id, {
    required String code,
    required String name,
    int? maxAge,
    required int rank,
  }) async => (await _api.updateAgeCategory(
    xTenantId: _t,
    ageCategoryId: id,
    updateAgeCategoryRequest: api.UpdateAgeCategoryRequest(
      (b) => b
        ..code = code
        ..name = name
        ..maxAge = maxAge
        ..rank = rank
        ..clear = clearList({
          api.UpdateAgeCategoryRequestClearEnum.maxAge: maxAge,
        }),
    ),
  )).data!;

  @override
  Future<void> delete(String id) async {
    await _api.deleteAgeCategory(xTenantId: _t, ageCategoryId: id);
  }
}
