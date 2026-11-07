import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/kit.dart';
import '../../../core/ui/temporary_password_dialog.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/roster_providers.dart';

/// Admin: pending inbox with approve / reject. Coach: my requests + cancel.
class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  bool _pendingOnly = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final caps = ref.watch(capabilitiesProvider);
    final approvals = ref.watch(approvalsProvider);
    return SubPage(
      title: caps.canDecideApprovals ? l.approvalsTitle : l.approvalsMine,
      parentPath: '/players',
      child: Guarded(
        allowed: caps.canSeeApprovals,
        child: Column(
          children: [
            ContentFrame(
              child: Padding(
                padding: const EdgeInsets.only(top: HoopsSpace.md),
                child: SegmentedButton<bool>(
                  key: const Key('approvals-filter'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(l.approvalStatusPending),
                    ),
                    ButtonSegment(value: false, label: Text(l.all)),
                  ],
                  selected: {_pendingOnly},
                  onSelectionChanged: (s) =>
                      setState(() => _pendingOnly = s.first),
                ),
              ),
            ),
            Expanded(
              child: AsyncBody<List<api.ApprovalRequest>>(
                value: approvals,
                onRetry: () => ref.invalidate(approvalsProvider),
                isEmpty: (d) => d
                    .where(
                      (r) =>
                          !_pendingOnly ||
                          r.status == api.ApprovalStatus.PENDING,
                    )
                    .isEmpty,
                emptyMessage: l.approvalsEmpty,
                builder: (context, data) {
                  final shown = [
                    for (final r in data)
                      if (!_pendingOnly ||
                          r.status == api.ApprovalStatus.PENDING)
                        r,
                  ];
                  return PageBody(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: HoopsSpace.gap,
                        children: [
                          for (final r in shown)
                            _ApprovalCard(request: r, caps: caps),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends ConsumerWidget {
  const _ApprovalCard({required this.request, required this.caps});
  final api.ApprovalRequest request;
  final Capabilities caps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall!.copyWith(
      color: HoopsTokens.colorsOf(context).inkMuted,
    );
    final pending = request.status == api.ApprovalStatus.PENDING;
    final notifier = ref.read(approvalsProvider.notifier);
    return SectionCard(
      key: Key('approval-${request.id}'),
      title: request.player.displayName,
      actions: [
        StatusChip(
          request.status.label(l),
          tone: pending
              ? HoopsTone.warning
              : request.status == api.ApprovalStatus.APPROVED
              ? HoopsTone.success
              : HoopsTone.neutral,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: HoopsSpace.xs,
        children: [
          Text(request.action.label(l)),
          Text(
            l.approvalRequestedBy(request.requestedBy.displayName),
            style: muted,
          ),
          if (request.payload.note != null && request.payload.note!.isNotEmpty)
            Text(request.payload.note!, style: muted),
          if (request.payload.reason != null &&
              request.payload.reason!.isNotEmpty)
            Text(request.payload.reason!, style: muted),
          if (request.decisionNote != null && request.decisionNote!.isNotEmpty)
            Text(l.approvalDecisionNote(request.decisionNote!), style: muted),
          if (pending && caps.canDecideApprovals)
            Padding(
              padding: const EdgeInsets.only(top: HoopsSpace.sm),
              child: Wrap(
                spacing: HoopsSpace.sm,
                runSpacing: HoopsSpace.sm,
                children: [
                  FilledButton(
                    key: Key('approve-${request.id}'),
                    onPressed: () async {
                      final note = await noteDialog(
                        context,
                        title: l.approvalApprove,
                        confirmLabel: l.approvalApprove,
                      );
                      if (note == null || !context.mounted) return;
                      // The card leaves the pending list once approved: keep a context that outlives it.
                      final nav = Navigator.of(
                        context,
                        rootNavigator: true,
                      ).context;
                      api.ApprovalRequestWithPassword? approved;
                      final ok = await runAction(
                        context,
                        () async => approved = await notifier.approve(
                          request.id,
                          note: note.isEmpty ? null : note,
                        ),
                      );
                      if (!ok || !nav.mounted) return;
                      final password = approved?.temporaryPassword;
                      if (password == null) {
                        ScaffoldMessenger.maybeOf(nav)?.showSnackBar(
                          SnackBar(content: Text(l.approvalApproved)),
                        );
                      } else {
                        await announceLogin(
                          nav,
                          person: request.player.displayName,
                          temporaryPassword: password,
                          done: l.approvalApproved,
                        );
                      }
                    },
                    child: Text(l.approvalApprove),
                  ),
                  OutlinedButton(
                    key: Key('reject-${request.id}'),
                    onPressed: () async {
                      final note = await noteDialog(
                        context,
                        title: l.approvalReject,
                        confirmLabel: l.approvalReject,
                        required: true,
                      );
                      if (note == null || !context.mounted) return;
                      await runAction(
                        context,
                        () => notifier.reject(request.id, note: note),
                        success: l.approvalRejected,
                      );
                    },
                    child: Text(l.approvalReject),
                  ),
                ],
              ),
            ),
          if (pending &&
              !caps.canDecideApprovals &&
              request.requestedBy.personId == caps.personId)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: Key('cancel-${request.id}'),
                onPressed: () async {
                  if (!await confirmDialog(
                    context,
                    message: l.approvalCancelConfirm,
                  )) {
                    return;
                  }
                  if (!context.mounted) return;
                  await runAction(
                    context,
                    () => notifier.cancel(request.id),
                    success: l.approvalCancelled,
                  );
                },
                child: Text(l.approvalCancel),
              ),
            ),
        ],
      ),
    );
  }
}
