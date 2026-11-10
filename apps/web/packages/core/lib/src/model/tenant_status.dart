//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tenant_status.g.dart';

class TenantStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ACTIVE')
  static const TenantStatus ACTIVE = _$ACTIVE;
  @BuiltValueEnumConst(wireName: r'SUSPENDED')
  static const TenantStatus SUSPENDED = _$SUSPENDED;
  @BuiltValueEnumConst(wireName: r'WITHDRAWN')
  static const TenantStatus WITHDRAWN = _$WITHDRAWN;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const TenantStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<TenantStatus> get serializer => _$tenantStatusSerializer;

  const TenantStatus._(String name): super(name);

  static BuiltSet<TenantStatus> get values => _$values;
  static TenantStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class TenantStatusMixin = Object with _$TenantStatusMixin;

