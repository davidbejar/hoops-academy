import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/fake_athlete.dart';
import '../../support/pump_helpers.dart';

FakePlansRepository _plans() => FakePlansRepository(
  plans: [
    planOf('tpl-1', 'Fundamentos U12', template: true, items: [planItem('t1', 'Bote', 0, minutes: 15)]),
    planOf('plan-1', 'Tiro básico', items: [planItem('i1', 'Calentamiento', 0, minutes: 10), planItem('i2', 'Tiros libres', 1, minutes: 20, sets: 3, reps: 10, video: 'https://v.example/tl')]),
    planOf('plan-2', 'Defensa', items: []),
  ],
);

void main() {
  group('plan library', () {
    testWidgets('own plans first, templates on the second tab; summary shows items and minutes', (tester) async {
      await pumpAs(tester, roles: {TenantRole.coach}, staffTeamIds: {'t1'}, core: athleteCore(), athlete: FakeAthlete(plans: _plans()), location: '/training/plans');
      expect(find.text('Tiro básico'), findsOneWidget);
      expect(find.text('2 ejercicios · 30 min'), findsOneWidget);
      expect(find.text('Fundamentos U12'), findsNothing);
      await tester.tap(find.byKey(const Key('tab-templates')));
      await tester.pumpAndSettle();
      expect(find.text('Fundamentos U12'), findsOneWidget);
      expect(find.byKey(const Key('plan-use-tpl-1')), findsOneWidget);
    });

    testWidgets('empty, loading and error', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(), location: '/training/plans');
      expect(find.textContaining('Aún no hay planes propios'), findsOneWidget);
      final hung = FakeAthlete(plans: FakePlansRepository()..hang = true);
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: hung, location: '/training/plans', settle: false);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      final failing = FakeAthlete(plans: FakePlansRepository()..failWith = StateError('x'));
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: failing, location: '/training/plans');
      expect(find.text('Reintentar'), findsWidgets);
    });

    testWidgets('search filters by name through the repository', (tester) async {
      final plans = _plans();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(plans: plans), location: '/training/plans');
      await tester.enterText(find.byKey(const Key('plan-search')), 'defen');
      await tester.pumpAndSettle();
      expect(plans.lastQuery, 'defen');
      expect(find.text('Defensa'), findsOneWidget);
      expect(find.text('Tiro básico'), findsNothing);
    });

    testWidgets('using a template copies it first and opens the copy', (tester) async {
      final plans = _plans();
      await pumpAs(tester, roles: {TenantRole.coach}, staffTeamIds: {'t1'}, core: athleteCore(), athlete: FakeAthlete(plans: plans), location: '/training/plans');
      await tester.tap(find.byKey(const Key('tab-templates')));
      await tester.pumpAndSettle();
      await tapKey(tester, 'plan-use-tpl-1');
      expect(plans.copiedFrom, 'tpl-1');
      expect(find.byKey(const Key('item-add')), findsOneWidget, reason: 'the copy is editable');
      expect(find.text('Plantilla copiada a tus planes'), findsOneWidget);
    });

    testWidgets('a template opened directly is read-only with a hint', (tester) async {
      await pumpAs(tester, roles: {TenantRole.coach}, staffTeamIds: {'t1'}, core: athleteCore(), athlete: FakeAthlete(plans: _plans()), location: '/training/plans/tpl-1');
      expect(find.byKey(const Key('template-hint')), findsOneWidget);
      expect(find.byKey(const Key('item-add')), findsNothing);
      expect(find.byKey(const Key('item-menu-t1')), findsNothing);
      expect(find.byKey(const Key('plan-assign')), findsNothing);
    });

    testWidgets('create a plan opens its editor', (tester) async {
      final plans = _plans();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(plans: plans), location: '/training/plans');
      await tapKey(tester, 'plan-new');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsOneWidget);
      await enter(tester, 'plan-name', 'Pase y movimiento');
      await tapKey(tester, 'form-submit');
      expect(plans.planList.last.name, 'Pase y movimiento');
      expect(find.text('Este plan aún no tiene ejercicios'), findsOneWidget);
    });
  });

  group('plan editor', () {
    testWidgets('shows items with duration, sets x reps and video link', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(plans: _plans()), location: '/training/plans/plan-1');
      expect(find.text('Calentamiento'), findsOneWidget);
      expect(find.textContaining('20 min · 3 × 10'), findsOneWidget);
      expect(find.text('https://v.example/tl'), findsOneWidget);
    });

    testWidgets('add item validates the video link, then stores durations, sets and reps', (tester) async {
      final plans = _plans();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(plans: plans), location: '/training/plans/plan-2');
      await tapKey(tester, 'item-add');
      await enter(tester, 'item-title', 'Slides defensivos');
      await enter(tester, 'item-video', 'http://insecure');
      await tapKey(tester, 'form-submit');
      expect(find.text('Debe empezar por https://'), findsOneWidget);
      await enter(tester, 'item-video', 'https://v.example/slide');
      await enter(tester, 'item-duration', '12');
      await enter(tester, 'item-sets', '4');
      await enter(tester, 'item-reps', '8');
      await tapKey(tester, 'form-submit');
      final item = plans.planList.firstWhere((p) => p.id == 'plan-2').items.single;
      expect((item.title, item.durationMinutes, item.sets, item.repetitions, item.videoUrl), ('Slides defensivos', 12, 4, 8, 'https://v.example/slide'));
      expect(find.text('Slides defensivos'), findsOneWidget);
    });

    testWidgets('editing an item clears the emptied sets, repetitions and video; the duration stays', (tester) async {
      final plans = _plans();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(plans: plans), location: '/training/plans/plan-1');
      await tapKey(tester, 'item-menu-i2');
      await tester.tap(find.text('Editar').last);
      await tester.pumpAndSettle();
      await enter(tester, 'item-sets', '');
      await enter(tester, 'item-reps', '');
      await enter(tester, 'item-video', '');
      await tapKey(tester, 'form-submit');
      final clear = plans.updatedItem!.clear!;
      expect(clear, containsAll([ath.UpdatePlanItemRequestClearEnum.sets, ath.UpdatePlanItemRequestClearEnum.repetitions, ath.UpdatePlanItemRequestClearEnum.videoUrl]));
      expect(clear, isNot(contains(ath.UpdatePlanItemRequestClearEnum.durationMinutes)));
      final item = plans.planList.firstWhere((p) => p.id == 'plan-1').items.firstWhere((i) => i.id == 'i2');
      expect((item.durationMinutes, item.sets, item.repetitions, item.videoUrl), (20, null, null, null));
      expect(find.text('https://v.example/tl'), findsNothing);
    });

    testWidgets('moving an item down sends the new permutation to the repository', (tester) async {
      final plans = _plans();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(plans: plans), location: '/training/plans/plan-1');
      await tapKey(tester, 'item-menu-i1');
      await tester.tap(find.text('Bajar'));
      await tester.pumpAndSettle();
      expect(plans.lastOrder, ['i2', 'i1']);
      final order = tester.widgetList<Card>(find.byType(Card)).map((c) => c.key).whereType<ValueKey<String>>().map((k) => k.value).where((v) => v.startsWith('item-i'));
      expect(order.toList(), ['item-i2', 'item-i1']);
    });

    testWidgets('delete item asks for confirmation', (tester) async {
      final plans = _plans();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(plans: plans), location: '/training/plans/plan-1');
      await tapKey(tester, 'item-menu-i2');
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'dialog-confirm');
      expect(plans.planList.firstWhere((p) => p.id == 'plan-1').items.map((i) => i.id), ['i1']);
    });

    testWidgets('assign to a team with a due date and note', (tester) async {
      final plans = _plans();
      await pumpAs(tester, roles: {TenantRole.coach}, staffTeamIds: {'t1'}, core: athleteCore(), athlete: FakeAthlete(plans: plans), location: '/training/plans/plan-1');
      await tapKey(tester, 'plan-assign');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsOneWidget);
      await tapKey(tester, 'assign-team');
      await tester.tap(find.text('Mini A (Leones)').last);
      await tester.pumpAndSettle();
      await enter(tester, 'assign-notes', 'Antes del viernes');
      await tapKey(tester, 'form-submit');
      expect(plans.assigned!.planId, 'plan-1');
      expect(plans.assigned!.teamId, 't1');
      expect(plans.assigned!.playerId, isNull);
      expect(plans.assigned!.notes, 'Antes del viernes');
      expect(find.text('Plan asignado'), findsOneWidget);
    });

    testWidgets('assign to a single player', (tester) async {
      final plans = _plans();
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(plans: plans), location: '/training/plans/plan-1');
      await tapKey(tester, 'plan-assign');
      await tester.tap(find.text('Un jugador'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'player-picker');
      await tester.tap(find.text('Mia Soto').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');
      expect(plans.assigned!.playerId, 'p3');
      expect(plans.assigned!.teamId, isNull);
    });

    testWidgets('PARENT/PLAYER cannot open the library (route guard)', (tester) async {
      await pumpAs(tester, roles: {TenantRole.player}, ownPlayerId: 'p1', core: athleteCore(), athlete: FakeAthlete(plans: _plans()), location: '/training/plans');
      expect(find.byKey(const Key('forbidden')), findsOneWidget);
    });
  });

  group('assignments and completion', () {
    FakeAthlete athlete() {
      final plans = _plans();
      final p = plans.planList[1];
      plans.assignmentList.addAll([
        assignmentOf('as1', p, teamId: 't1', due: ath.Date(2026, 11, 20), notes: 'Dos series'),
        assignmentOf('as2', p, playerId: 'p1', due: ath.Date(2026, 11, 25)),
      ]);
      plans.completionList.addAll([
        completionOf('c1', 'as1', 'p1', ath.CompletionStatus.DONE),
        completionOf('c2', 'as1', 'p2', ath.CompletionStatus.NOT_DONE, comment: 'Lesionado'),
        completionOf('c3', 'as1', 'p3', ath.CompletionStatus.PARTIAL),
      ]);
      return FakeAthlete(plans: plans);
    }

    testWidgets('staff overview shows progress counts per assignment', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: athlete(), location: '/training/assignments');
      expect(find.textContaining('1 hechos · 1 parciales · 1 no hechos'), findsOneWidget);
      expect(find.textContaining('Equipo: Mini A'), findsOneWidget);
    });

    testWidgets('empty overview', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: athleteCore(), athlete: FakeAthlete(), location: '/training/assignments');
      expect(find.text('No hay planes asignados'), findsOneWidget);
    });

    testWidgets('progress view lists every roster player with status and comment; staff can mark', (tester) async {
      final a = athlete();
      await pumpAs(tester, roles: {TenantRole.coach}, staffTeamIds: {'t1'}, core: athleteCore(), athlete: a, location: '/training/assignments/as1', size: const Size(360, 1400));
      expect(find.byKey(const Key('progress-p1')), findsOneWidget);
      expect(find.byKey(const Key('progress-p3')), findsOneWidget);
      expect(find.text('Lesionado'), findsOneWidget);
      await tapKey(tester, 'comp-as1-p3-DONE');
      await tester.enterText(find.byKey(const Key('note-field')), 'Completó en casa');
      await tapKey(tester, 'dialog-confirm');
      expect(a.plans.lastRecord!.status, ath.CompletionStatus.DONE);
      expect(a.plans.lastRecord!.playerId, 'p3');
      expect(a.plans.lastRecord!.comment, 'Completó en casa');
    });

    testWidgets('PLAYER marks own assignment DONE / PARTIAL / NOT_DONE from Me', (tester) async {
      final a = athlete();
      await pumpAs(tester, roles: {TenantRole.player}, ownPlayerId: 'p1', core: athleteCore(), athlete: a, location: '/me', size: const Size(360, 1400));
      await tapKey(tester, 'hub-tab-plans');
      expect(find.byKey(const Key('hub-assignment-as2')), findsOneWidget);
      await tapKey(tester, 'comp-as2-p1-PARTIAL');
      await tapKey(tester, 'dialog-confirm');
      expect(a.plans.lastRecord!.status, ath.CompletionStatus.PARTIAL);
      expect(a.plans.lastRecord!.comment, isNull);
      await tapKey(tester, 'comp-as2-p1-NOT_DONE');
      await tapKey(tester, 'dialog-confirm');
      expect(a.plans.lastRecord!.status, ath.CompletionStatus.NOT_DONE);
      expect(find.text('Marca guardada'), findsOneWidget);
    });
  });
}
