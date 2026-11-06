//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:hoops_athlete_api/src/date_serializer.dart';
import 'package:hoops_athlete_api/src/model/date.dart';

import 'package:hoops_athlete_api/src/model/attendance_entry.dart';
import 'package:hoops_athlete_api/src/model/attendance_input.dart';
import 'package:hoops_athlete_api/src/model/attendance_status.dart';
import 'package:hoops_athlete_api/src/model/band_status.dart';
import 'package:hoops_athlete_api/src/model/body_measurement.dart';
import 'package:hoops_athlete_api/src/model/body_measurement_input.dart';
import 'package:hoops_athlete_api/src/model/cancel_training_session_request.dart';
import 'package:hoops_athlete_api/src/model/completion_status.dart';
import 'package:hoops_athlete_api/src/model/copy_plan_items_request.dart';
import 'package:hoops_athlete_api/src/model/copy_training_plan_request.dart';
import 'package:hoops_athlete_api/src/model/create_injury_request.dart';
import 'package:hoops_athlete_api/src/model/create_plan_assignment_request.dart';
import 'package:hoops_athlete_api/src/model/create_training_plan_request.dart';
import 'package:hoops_athlete_api/src/model/create_training_session_request.dart';
import 'package:hoops_athlete_api/src/model/day_of_week.dart';
import 'package:hoops_athlete_api/src/model/gender.dart';
import 'package:hoops_athlete_api/src/model/injury.dart';
import 'package:hoops_athlete_api/src/model/injury_page.dart';
import 'package:hoops_athlete_api/src/model/injury_severity.dart';
import 'package:hoops_athlete_api/src/model/injury_status.dart';
import 'package:hoops_athlete_api/src/model/norm_band.dart';
import 'package:hoops_athlete_api/src/model/page_meta.dart';
import 'package:hoops_athlete_api/src/model/person_ref.dart';
import 'package:hoops_athlete_api/src/model/physical_test_norm.dart';
import 'package:hoops_athlete_api/src/model/physical_test_norm_input.dart';
import 'package:hoops_athlete_api/src/model/physical_test_result.dart';
import 'package:hoops_athlete_api/src/model/physical_test_result_input.dart';
import 'package:hoops_athlete_api/src/model/physical_test_result_page.dart';
import 'package:hoops_athlete_api/src/model/physical_test_type.dart';
import 'package:hoops_athlete_api/src/model/physical_test_type_input.dart';
import 'package:hoops_athlete_api/src/model/plan_assignment.dart';
import 'package:hoops_athlete_api/src/model/plan_assignment_page.dart';
import 'package:hoops_athlete_api/src/model/plan_completion.dart';
import 'package:hoops_athlete_api/src/model/plan_completion_page.dart';
import 'package:hoops_athlete_api/src/model/plan_item.dart';
import 'package:hoops_athlete_api/src/model/plan_item_input.dart';
import 'package:hoops_athlete_api/src/model/plan_item_match.dart';
import 'package:hoops_athlete_api/src/model/plan_item_ref.dart';
import 'package:hoops_athlete_api/src/model/plan_progress.dart';
import 'package:hoops_athlete_api/src/model/plan_progress_counts.dart';
import 'package:hoops_athlete_api/src/model/planned_absence.dart';
import 'package:hoops_athlete_api/src/model/planned_absence_input.dart';
import 'package:hoops_athlete_api/src/model/planned_absence_page.dart';
import 'package:hoops_athlete_api/src/model/player_availability.dart';
import 'package:hoops_athlete_api/src/model/player_progress.dart';
import 'package:hoops_athlete_api/src/model/problem.dart';
import 'package:hoops_athlete_api/src/model/problem_violation.dart';
import 'package:hoops_athlete_api/src/model/record_attendance_request.dart';
import 'package:hoops_athlete_api/src/model/record_plan_completion_request.dart';
import 'package:hoops_athlete_api/src/model/reorder_plan_items_request.dart';
import 'package:hoops_athlete_api/src/model/session_attendance.dart';
import 'package:hoops_athlete_api/src/model/training_plan.dart';
import 'package:hoops_athlete_api/src/model/training_plan_summary.dart';
import 'package:hoops_athlete_api/src/model/training_plan_summary_page.dart';
import 'package:hoops_athlete_api/src/model/training_schedule.dart';
import 'package:hoops_athlete_api/src/model/training_schedule_input.dart';
import 'package:hoops_athlete_api/src/model/training_session.dart';
import 'package:hoops_athlete_api/src/model/training_session_page.dart';
import 'package:hoops_athlete_api/src/model/training_session_status.dart';
import 'package:hoops_athlete_api/src/model/update_body_measurement_request.dart';
import 'package:hoops_athlete_api/src/model/update_injury_request.dart';
import 'package:hoops_athlete_api/src/model/update_physical_test_result_request.dart';
import 'package:hoops_athlete_api/src/model/update_physical_test_type_request.dart';
import 'package:hoops_athlete_api/src/model/update_plan_item_request.dart';
import 'package:hoops_athlete_api/src/model/update_planned_absence_request.dart';
import 'package:hoops_athlete_api/src/model/update_training_plan_request.dart';
import 'package:hoops_athlete_api/src/model/update_training_schedule_request.dart';
import 'package:hoops_athlete_api/src/model/update_training_session_request.dart';
import 'package:hoops_athlete_api/src/model/usage_report.dart';

part 'serializers.g.dart';

@SerializersFor([
  AttendanceEntry,
  AttendanceInput,
  AttendanceStatus,
  BandStatus,
  BodyMeasurement,
  BodyMeasurementInput,
  CancelTrainingSessionRequest,
  CompletionStatus,
  CopyPlanItemsRequest,
  CopyTrainingPlanRequest,
  CreateInjuryRequest,
  CreatePlanAssignmentRequest,
  CreateTrainingPlanRequest,
  CreateTrainingSessionRequest,
  DayOfWeek,
  Gender,
  Injury,
  InjuryPage,
  InjurySeverity,
  InjuryStatus,
  NormBand,
  PageMeta,
  PersonRef,
  PhysicalTestNorm,
  PhysicalTestNormInput,
  PhysicalTestResult,
  PhysicalTestResultInput,
  PhysicalTestResultPage,
  PhysicalTestType,
  PhysicalTestTypeInput,
  PlanAssignment,
  PlanAssignmentPage,
  PlanCompletion,
  PlanCompletionPage,
  PlanItem,
  PlanItemInput,
  PlanItemMatch,
  PlanItemRef,
  PlanProgress,
  PlanProgressCounts,
  PlannedAbsence,
  PlannedAbsenceInput,
  PlannedAbsencePage,
  PlayerAvailability,
  PlayerProgress,
  Problem,
  ProblemViolation,
  RecordAttendanceRequest,
  RecordPlanCompletionRequest,
  ReorderPlanItemsRequest,
  SessionAttendance,
  TrainingPlan,
  TrainingPlanSummary,
  TrainingPlanSummaryPage,
  TrainingSchedule,
  TrainingScheduleInput,
  TrainingSession,
  TrainingSessionPage,
  TrainingSessionStatus,
  UpdateBodyMeasurementRequest,
  UpdateInjuryRequest,
  UpdatePhysicalTestResultRequest,
  UpdatePhysicalTestTypeRequest,
  UpdatePlanItemRequest,
  UpdatePlannedAbsenceRequest,
  UpdateTrainingPlanRequest,
  UpdateTrainingScheduleRequest,
  UpdateTrainingSessionRequest,
  UsageReport,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlanItemMatch)]),
        () => ListBuilder<PlanItemMatch>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltSet, [FullType(String)]),
        () => SetBuilder<String>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlanItem)]),
        () => ListBuilder<PlanItem>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TrainingPlanSummary)]),
        () => ListBuilder<TrainingPlanSummary>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlanCompletion)]),
        () => ListBuilder<PlanCompletion>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(BodyMeasurement)]),
        () => ListBuilder<BodyMeasurement>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlanItemRef)]),
        () => ListBuilder<PlanItemRef>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlanAssignment)]),
        () => ListBuilder<PlanAssignment>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(AttendanceEntry)]),
        () => ListBuilder<AttendanceEntry>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlannedAbsence)]),
        () => ListBuilder<PlannedAbsence>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ProblemViolation)]),
        () => ListBuilder<ProblemViolation>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PhysicalTestResult)]),
        () => ListBuilder<PhysicalTestResult>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlanItemInput)]),
        () => ListBuilder<PlanItemInput>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TrainingSession)]),
        () => ListBuilder<TrainingSession>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlayerProgress)]),
        () => ListBuilder<PlayerProgress>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltMap, [FullType(String), FullType(int)]),
        () => MapBuilder<String, int>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PhysicalTestType)]),
        () => ListBuilder<PhysicalTestType>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(TrainingSchedule)]),
        () => ListBuilder<TrainingSchedule>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(AttendanceInput)]),
        () => ListBuilder<AttendanceInput>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(String)]),
        () => ListBuilder<String>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PhysicalTestNorm)]),
        () => ListBuilder<PhysicalTestNorm>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Injury)]),
        () => ListBuilder<Injury>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
