//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:built_value/serializer.dart';
import 'package:hoops_athlete_api/src/serializers.dart';
import 'package:hoops_athlete_api/src/auth/api_key_auth.dart';
import 'package:hoops_athlete_api/src/auth/basic_auth.dart';
import 'package:hoops_athlete_api/src/auth/bearer_auth.dart';
import 'package:hoops_athlete_api/src/auth/oauth.dart';
import 'package:hoops_athlete_api/src/api/attendance_api.dart';
import 'package:hoops_athlete_api/src/api/body_measurements_api.dart';
import 'package:hoops_athlete_api/src/api/injuries_api.dart';
import 'package:hoops_athlete_api/src/api/physical_tests_api.dart';
import 'package:hoops_athlete_api/src/api/plan_assignments_api.dart';
import 'package:hoops_athlete_api/src/api/plan_completions_api.dart';
import 'package:hoops_athlete_api/src/api/planned_absences_api.dart';
import 'package:hoops_athlete_api/src/api/training_plans_api.dart';
import 'package:hoops_athlete_api/src/api/training_schedules_api.dart';
import 'package:hoops_athlete_api/src/api/training_sessions_api.dart';

class HoopsAthleteApi {
  static const String basePath = r'http://localhost';

  final Dio dio;
  final Serializers serializers;

  HoopsAthleteApi({
    Dio? dio,
    Serializers? serializers,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  })  : this.serializers = serializers ?? standardSerializers,
        this.dio = dio ??
            Dio(BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            )) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor) as OAuthInterceptor).tokens[name] = token;
    }
  }

  /// Removes the OAuth token associated with the given [name].
  ///
  /// If no [OAuthInterceptor] is registered or no token exists for the given
  /// [name], this method has no effect.
  void removeOAuthToken(String name) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor) as OAuthInterceptor).tokens.remove(name);
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor) as BearerAuthInterceptor).tokens[name] = token;
    }
  }

  /// Removes the bearer authentication token associated with the given [name].
  ///
  /// If no [BearerAuthInterceptor] is registered or no token exists for the
  /// given [name], this method has no effect.
  void removeBearerAuth(String name) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor) as BearerAuthInterceptor).tokens.remove(name);
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor) as BasicAuthInterceptor).authInfo[name] = BasicAuthInfo(username, password);
    }
  }

  /// Removes the basic authentication credentials associated with the given [name].
  ///
  /// If no [BasicAuthInterceptor] is registered or no credentials exist for the
  /// given [name], this method has no effect.
  void removeBasicAuth(String name) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor) as BasicAuthInterceptor).authInfo.remove(name);
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((element) => element is ApiKeyAuthInterceptor) as ApiKeyAuthInterceptor).apiKeys[name] = apiKey;
    }
  }

  /// Removes the API key associated with the given [name].
  ///
  /// If no [ApiKeyAuthInterceptor] is registered or no API key exists for the
  /// given [name], this method has no effect.
  void removeApiKey(String name) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((element) => element is ApiKeyAuthInterceptor) as ApiKeyAuthInterceptor).apiKeys.remove(name);
    }
  }

  /// Get AttendanceApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AttendanceApi getAttendanceApi() {
    return AttendanceApi(dio, serializers);
  }

  /// Get BodyMeasurementsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  BodyMeasurementsApi getBodyMeasurementsApi() {
    return BodyMeasurementsApi(dio, serializers);
  }

  /// Get InjuriesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  InjuriesApi getInjuriesApi() {
    return InjuriesApi(dio, serializers);
  }

  /// Get PhysicalTestsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PhysicalTestsApi getPhysicalTestsApi() {
    return PhysicalTestsApi(dio, serializers);
  }

  /// Get PlanAssignmentsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PlanAssignmentsApi getPlanAssignmentsApi() {
    return PlanAssignmentsApi(dio, serializers);
  }

  /// Get PlanCompletionsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PlanCompletionsApi getPlanCompletionsApi() {
    return PlanCompletionsApi(dio, serializers);
  }

  /// Get PlannedAbsencesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PlannedAbsencesApi getPlannedAbsencesApi() {
    return PlannedAbsencesApi(dio, serializers);
  }

  /// Get TrainingPlansApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TrainingPlansApi getTrainingPlansApi() {
    return TrainingPlansApi(dio, serializers);
  }

  /// Get TrainingSchedulesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TrainingSchedulesApi getTrainingSchedulesApi() {
    return TrainingSchedulesApi(dio, serializers);
  }

  /// Get TrainingSessionsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TrainingSessionsApi getTrainingSessionsApi() {
    return TrainingSessionsApi(dio, serializers);
  }
}
