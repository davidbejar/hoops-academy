import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/labels.dart';
import '../../../core/ui/page_scaffold.dart';
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
            Padding(
              padding: const EdgeInsets.all(AppTokens.spaceMd),
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
                builder: (context, data) => ListView(
                  children: [
                    for (final r in data)
                      if (!_pendingOnly ||
                          r.status == api.ApprovalStatus.PENDING)
                        _ApprovalCard(request: r, caps: caps),
                  ],
                ),
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
    final theme = Theme.of(context);
    final pending = request.status == api.ApprovalStatus.PENDING;
    final notifier = ref.read(approvalsProvider.notifier);
    return Card(
      key: Key('approval-${request.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceMd,
        vertical: AppTokens.spaceXs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.player.displayName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                InfoChip(
                  request.status.label(l),
                  tone: pending
                      ? ChipTone.warn
                      : request.status == api.ApprovalStatus.APPROVED
                      ? ChipTone.good
                      : ChipTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceXs),
            Text(request.action.label(l)),
            Text(
              l.approvalRequestedBy(request.requestedBy.displayName),
              style: theme.textTheme.bodySmall,
            ),
            if (request.payload.note != null &&
                request.payload.note!.isNotEmpty)
              Text(request.payload.note!, style: theme.textTheme.bodySmall),
            if (request.payload.reason != null &&
                request.payload.reason!.isNotEmpty)
              Text(request.payload.reason!, style: theme.textTheme.bodySmall),
            if (request.decisionNote != null &&
                request.decisionNote!.isNotEmpty)
              Text(
                l.approvalDecisionNote(request.decisionNote!),
                style: theme.textTheme.bodySmall,
              ),
            if (pending && caps.canDecideApprovals)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.spaceSm),
                child: Wrap(
                  spacing: AppTokens.spaceSm,
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
                        await runAction(
                          context,
                          () => notifier.approve(
                            request.id,
                            note: note.isEmpty ? null : note,
                          ),
                          success: l.approvalApproved,
                        );
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
      ),
    );
  }
}
