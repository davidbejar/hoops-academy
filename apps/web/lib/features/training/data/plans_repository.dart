import '../../../core/api/athlete_api.dart' as ath;

/// Training plans, assignments and completions.
abstract class PlansRepository {
  Future<List<ath.TrainingPlanSummary>> plans({
    required bool templates,
    String? query,
  });
  Future<ath.TrainingPlan> plan(String planId);
  Future<ath.TrainingPlan> createPlan(ath.CreateTrainingPlanRequest request);
  Future<ath.TrainingPlan> updatePlan(
    String planId,
    ath.UpdateTrainingPlanRequest request,
  );
  Future<void> deletePlan(String planId);

  /// Copy-on-use: templates are read-only, so they are copied before use.
  Future<ath.TrainingPlan> copyPlan(String planId, {String? name});
  Future<ath.PlanItem> addItem(String planId, ath.PlanItemInput input);
  Future<ath.PlanItem> updateItem(
    String planId,
    String itemId,
    ath.UpdatePlanItemRequest request,
  );
  Future<void> deleteItem(String planId, String itemId);
  Future<List<ath.PlanItem>> reorder(String planId, List<String> itemIds);

  Future<List<ath.PlanAssignment>> assignments({
    String? teamId,
    String? playerId,
  });
  Future<ath.PlanAssignment> assign(ath.CreatePlanAssignmentRequest request);
  Future<void> deleteAssignment(String assignmentId);

  Future<List<ath.PlanCompletion>> completions({
    String? assignmentId,
    String? playerId,
  });
  Future<ath.PlanCompletion> record(
    String assignmentId,
    String playerId,
    ath.CompletionStatus status, {
    String? comment,
  });
}

class ApiPlansRepository implements PlansRepository {
  ApiPlansRepository(ath.HoopsAthleteApi client, this._t)
    : _plans = client.getTrainingPlansApi(),
      _assignments = client.getPlanAssignmentsApi(),
      _completions = client.getPlanCompletionsApi();

  final ath.TrainingPlansApi _plans;
  final ath.PlanAssignmentsApi _assignments;
  final ath.PlanCompletionsApi _completions;
  final String _t;

  @override
  Future<List<ath.TrainingPlanSummary>> plans({
    required bool templates,
    String? query,
  }) async => (await _plans.listTrainingPlans(
    xTenantId: _t,
    template: templates,
    q: query,
    size: 100,
  )).data!.items.toList();

  @override
  Future<ath.TrainingPlan> plan(String planId) async =>
      (await _plans.getTrainingPlan(xTenantId: _t, planId: planId)).data!;

  @override
  Future<ath.TrainingPlan> createPlan(
    ath.CreateTrainingPlanRequest request,
  ) async => (await _plans.createTrainingPlan(
    xTenantId: _t,
    createTrainingPlanRequest: request,
  )).data!;

  @override
  Future<ath.TrainingPlan> updatePlan(
    String planId,
    ath.UpdateTrainingPlanRequest request,
  ) async => (await _plans.updateTrainingPlan(
    xTenantId: _t,
    planId: planId,
    updateTrainingPlanRequest: request,
  )).data!;

  @override
  Future<void> deletePlan(String planId) async {
    await _plans.deleteTrainingPlan(xTenantId: _t, planId: planId);
  }

  @override
  Future<ath.TrainingPlan> copyPlan(String planId, {String? name}) async =>
      (await _plans.copyTrainingPlan(
        xTenantId: _t,
        planId: planId,
        copyTrainingPlanRequest: ath.CopyTrainingPlanRequest(
          (b) => b.name = name,
        ),
      )).data!;

  @override
  Future<ath.PlanItem> addItem(String planId, ath.PlanItemInput input) async =>
      (await _plans.addPlanItem(
        xTenantId: _t,
        planId: planId,
        planItemInput: input,
      )).data!;

  @override
  Future<ath.PlanItem> updateItem(
    String planId,
    String itemId,
    ath.UpdatePlanItemRequest request,
  ) async => (await _plans.updatePlanItem(
    xTenantId: _t,
    planId: planId,
    itemId: itemId,
    updatePlanItemRequest: request,
  )).data!;

  @override
  Future<void> deleteItem(String planId, String itemId) async {
    await _plans.deletePlanItem(xTenantId: _t, planId: planId, itemId: itemId);
  }

  @override
  Future<List<ath.PlanItem>> reorder(
    String planId,
    List<String> itemIds,
  ) async => (await _plans.reorderPlanItems(
    xTenantId: _t,
    planId: planId,
    reorderPlanItemsRequest: ath.ReorderPlanItemsRequest(
      (b) => b.itemIds.replace(itemIds),
    ),
  )).data!.toList();

  @override
  Future<List<ath.PlanAssignment>> assignments({
    String? teamId,
    String? playerId,
  }) async => (await _assignments.listPlanAssignments(
    xTenantId: _t,
    teamId: teamId,
    playerId: playerId,
    size: 100,
  )).data!.items.toList();

  @override
  Future<ath.PlanAssignment> assign(
    ath.CreatePlanAssignmentRequest request,
  ) async => (await _assignments.createPlanAssignment(
    xTenantId: _t,
    createPlanAssignmentRequest: request,
  )).data!;

  @override
  Future<void> deleteAssignment(String assignmentId) async {
    await _assignments.deletePlanAssignment(
      xTenantId: _t,
      assignmentId: assignmentId,
    );
  }

  @override
  Future<List<ath.PlanCompletion>> completions({
    String? assignmentId,
    String? playerId,
  }) async => (await _completions.listPlanCompletions(
    xTenantId: _t,
    assignmentId: assignmentId,
    playerId: playerId,
    size: 100,
  )).data!.items.toList();

  @override
  Future<ath.PlanCompletion> record(
    String assignmentId,
    String playerId,
    ath.CompletionStatus status, {
    String? comment,
  }) async => (await _completions.recordPlanCompletion(
    xTenantId: _t,
    assignmentId: assignmentId,
    playerId: playerId,
    recordPlanCompletionRequest: ath.RecordPlanCompletionRequest(
      (b) => b
        ..status = status
        ..comment = comment,
    ),
  )).data!;
}
