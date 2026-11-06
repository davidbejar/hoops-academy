// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (Serializers().toBuilder()
      ..add(AttendanceEntry.serializer)
      ..add(AttendanceInput.serializer)
      ..add(AttendanceStatus.serializer)
      ..add(BandStatus.serializer)
      ..add(BodyMeasurement.serializer)
      ..add(BodyMeasurementInput.serializer)
      ..add(CancelTrainingSessionRequest.serializer)
      ..add(CompletionStatus.serializer)
      ..add(CopyPlanItemsRequest.serializer)
      ..add(CopyTrainingPlanRequest.serializer)
      ..add(CreateInjuryRequest.serializer)
      ..add(CreatePlanAssignmentRequest.serializer)
      ..add(CreateTrainingPlanRequest.serializer)
      ..add(CreateTrainingSessionRequest.serializer)
      ..add(DayOfWeek.serializer)
      ..add(Gender.serializer)
      ..add(Injury.serializer)
      ..add(InjuryPage.serializer)
      ..add(InjurySeverity.serializer)
      ..add(InjuryStatus.serializer)
      ..add(NormBand.serializer)
      ..add(PageMeta.serializer)
      ..add(PersonRef.serializer)
      ..add(PhysicalTestNorm.serializer)
      ..add(PhysicalTestNormInput.serializer)
      ..add(PhysicalTestResult.serializer)
      ..add(PhysicalTestResultInput.serializer)
      ..add(PhysicalTestResultPage.serializer)
      ..add(PhysicalTestType.serializer)
      ..add(PhysicalTestTypeInput.serializer)
      ..add(PlanAssignment.serializer)
      ..add(PlanAssignmentPage.serializer)
      ..add(PlanCompletion.serializer)
      ..add(PlanCompletionPage.serializer)
      ..add(PlanItem.serializer)
      ..add(PlanItemInput.serializer)
      ..add(PlanItemMatch.serializer)
      ..add(PlanItemRef.serializer)
      ..add(PlanProgress.serializer)
      ..add(PlanProgressCounts.serializer)
      ..add(PlannedAbsence.serializer)
      ..add(PlannedAbsenceInput.serializer)
      ..add(PlannedAbsencePage.serializer)
      ..add(PlayerAvailability.serializer)
      ..add(PlayerProgress.serializer)
      ..add(Problem.serializer)
      ..add(ProblemViolation.serializer)
      ..add(RecordAttendanceRequest.serializer)
      ..add(RecordPlanCompletionRequest.serializer)
      ..add(ReorderPlanItemsRequest.serializer)
      ..add(SessionAttendance.serializer)
      ..add(TrainingPlan.serializer)
      ..add(TrainingPlanSummary.serializer)
      ..add(TrainingPlanSummaryPage.serializer)
      ..add(TrainingSchedule.serializer)
      ..add(TrainingScheduleInput.serializer)
      ..add(TrainingSession.serializer)
      ..add(TrainingSessionPage.serializer)
      ..add(TrainingSessionStatus.serializer)
      ..add(UpdateBodyMeasurementRequest.serializer)
      ..add(UpdateBodyMeasurementRequestClearEnum.serializer)
      ..add(UpdateInjuryRequest.serializer)
      ..add(UpdateInjuryRequestClearEnum.serializer)
      ..add(UpdatePhysicalTestResultRequest.serializer)
      ..add(UpdatePhysicalTestResultRequestClearEnum.serializer)
      ..add(UpdatePhysicalTestTypeRequest.serializer)
      ..add(UpdatePhysicalTestTypeRequestClearEnum.serializer)
      ..add(UpdatePlanItemRequest.serializer)
      ..add(UpdatePlanItemRequestClearEnum.serializer)
      ..add(UpdatePlannedAbsenceRequest.serializer)
      ..add(UpdatePlannedAbsenceRequestClearEnum.serializer)
      ..add(UpdateTrainingPlanRequest.serializer)
      ..add(UpdateTrainingPlanRequestClearEnum.serializer)
      ..add(UpdateTrainingScheduleRequest.serializer)
      ..add(UpdateTrainingScheduleRequestClearEnum.serializer)
      ..add(UpdateTrainingSessionRequest.serializer)
      ..add(UpdateTrainingSessionRequestClearEnum.serializer)
      ..add(UpdateTrainingSessionRequestStatusEnum.serializer)
      ..add(UsageReport.serializer)
      ..add(UsageReportServiceEnum.serializer)
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(AttendanceEntry)]),
          () => ListBuilder<AttendanceEntry>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(AttendanceInput)]),
          () => ListBuilder<AttendanceInput>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Injury)]),
          () => ListBuilder<Injury>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PhysicalTestResult)]),
          () => ListBuilder<PhysicalTestResult>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlanAssignment)]),
          () => ListBuilder<PlanAssignment>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlanCompletion)]),
          () => ListBuilder<PlanCompletion>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlanItem)]),
          () => ListBuilder<PlanItem>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlanItemInput)]),
          () => ListBuilder<PlanItemInput>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlanItemMatch)]),
          () => ListBuilder<PlanItemMatch>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlanItemRef)]),
          () => ListBuilder<PlanItemRef>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlannedAbsence)]),
          () => ListBuilder<PlannedAbsence>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlayerProgress)]),
          () => ListBuilder<PlayerProgress>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ProblemViolation)]),
          () => ListBuilder<ProblemViolation>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(TrainingPlanSummary)]),
          () => ListBuilder<TrainingPlanSummary>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(TrainingSession)]),
          () => ListBuilder<TrainingSession>())
      ..addBuilderFactory(
          const FullType(
              BuiltMap, const [const FullType(String), const FullType(int)]),
          () => MapBuilder<String, int>())
      ..addBuilderFactory(
          const FullType(BuiltSet, const [const FullType(String)]),
          () => SetBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltSet,
              const [const FullType(UpdateBodyMeasurementRequestClearEnum)]),
          () => SetBuilder<UpdateBodyMeasurementRequestClearEnum>())
      ..addBuilderFactory(
          const FullType(
              BuiltSet, const [const FullType(UpdateInjuryRequestClearEnum)]),
          () => SetBuilder<UpdateInjuryRequestClearEnum>())
      ..addBuilderFactory(
          const FullType(BuiltSet,
              const [const FullType(UpdatePhysicalTestResultRequestClearEnum)]),
          () => SetBuilder<UpdatePhysicalTestResultRequestClearEnum>())
      ..addBuilderFactory(
          const FullType(BuiltSet,
              const [const FullType(UpdatePhysicalTestTypeRequestClearEnum)]),
          () => SetBuilder<UpdatePhysicalTestTypeRequestClearEnum>())
      ..addBuilderFactory(
          const FullType(
              BuiltSet, const [const FullType(UpdatePlanItemRequestClearEnum)]),
          () => SetBuilder<UpdatePlanItemRequestClearEnum>())
      ..addBuilderFactory(
          const FullType(BuiltSet,
              const [const FullType(UpdatePlannedAbsenceRequestClearEnum)]),
          () => SetBuilder<UpdatePlannedAbsenceRequestClearEnum>())
      ..addBuilderFactory(
          const FullType(BuiltSet,
              const [const FullType(UpdateTrainingPlanRequestClearEnum)]),
          () => SetBuilder<UpdateTrainingPlanRequestClearEnum>())
      ..addBuilderFactory(
          const FullType(BuiltSet,
              const [const FullType(UpdateTrainingScheduleRequestClearEnum)]),
          () => SetBuilder<UpdateTrainingScheduleRequestClearEnum>())
      ..addBuilderFactory(
          const FullType(BuiltSet,
              const [const FullType(UpdateTrainingSessionRequestClearEnum)]),
          () => SetBuilder<UpdateTrainingSessionRequestClearEnum>()))
    .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
