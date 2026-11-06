import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/actions.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/game_clock.dart';
import '../application/live_match_controller.dart';
import '../domain/pending_event.dart';
import 'match_labels.dart';

/// Width of the period / clock column of a log line.
const _timeColumnWidth = HoopsSize.minTapTarget;

/// The play-by-play, each line with its sync state; own
/// rejected events can be discarded, voidable ones voided.
class EventLog extends ConsumerWidget {
  const EventLog({super.key, required this.live});
  final LiveMatch live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (live.log.isEmpty)
      return EmptyState(icon: Icons.history, title: l.matchBeforeStart);
    final ctl = ref.read(liveMatchProvider(live.match.id).notifier);
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final gutter = WidthClass.of(context).gutter;
    return ListView.separated(
      key: const Key('event-log'),
      padding: const EdgeInsets.symmetric(vertical: HoopsSpace.sm),
      itemCount: live.log.length,
      separatorBuilder: (_, _) => Divider(indent: gutter, endIndent: gutter),
      itemBuilder: (context, i) {
        final e = live.log[i];
        final rejected = e.status == EventStatus.rejected;
        final meta = e.event.meta;
        return ListTile(
          key: Key('log-${e.event.id}'),
          contentPadding: EdgeInsets.symmetric(horizontal: gutter),
          leading: SizedBox(
            width: _timeColumnWidth,
            child: Text(
              '${periodLabel(l, meta.period, live.rules.periodCount)}\n${formatClock(meta.clockSecondsRemaining)}',
              style: tabular(text.labelMedium!).copyWith(color: c.inkMuted),
            ),
          ),
          title: Text(
            describeEvent(l, live, e.event),
            style: e.voided
                ? text.bodyLarge!.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: c.inkMuted,
                  )
                : text.bodyLarge,
          ),
          subtitle: Text(
            [if (e.voided) l.matchVoided, syncLabel(l, e)].join(' · '),
            key: Key('log-state-${e.event.id}'),
            style: text.bodySmall!.copyWith(
              color: rejected ? c.danger.foreground : c.inkMuted,
            ),
          ),
          trailing: rejected && e.mine
              ? IconButton(
                  key: Key('log-discard-${e.event.id}'),
                  tooltip: l.matchDiscard,
                  icon: Icon(Icons.delete_outline, color: c.danger.foreground),
                  onPressed: () async {
                    if (await confirmDialog(
                          context,
                          message: l.matchDiscardConfirm,
                          confirmLabel: l.matchDiscard,
                        ) &&
                        context.mounted) {
                      await runAction(context, () => ctl.discard(e.event.id));
                    }
                  },
                )
              : e.canVoid && (!live.finished || live.rights.canRunMatch)
              ? IconButton(
                  key: Key('log-void-${e.event.id}'),
                  tooltip: l.matchVoidEvent,
                  icon: const Icon(Icons.block),
                  onPressed: () async {
                    if (await confirmDialog(
                          context,
                          message: l.matchVoidConfirm,
                          confirmLabel: l.matchVoidEvent,
                        ) &&
                        context.mounted) {
                      await runAction(context, () => ctl.voidEvent(e.event.id));
                    }
                  },
                )
              : null,
        );
      },
    );
  }
}
