import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../core/ui/actions.dart';
import '../../../core/ui/date_field.dart';
import '../../../core/ui/form_dialog.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tenant/application/tenant_providers.dart';
import '../../training/presentation/training_labels.dart' show two;

/// What the dialog hands to the caller: the fields of `UpdateMatchRequest`. A null [venue] means "emptied" (the
/// repository then sends it in `clear`); the periods are null when they must stay as they are.
typedef MatchEdit = ({
  String opponentName,
  DateTime scheduledAt,
  gen.HomeAway homeAway,
  String? venue,
  int? periodCount,
  int? periodMinutes,
});

/// Edits a match: opponent, date and time (academy zone), home/away, venue (clearable) and periods. The periods
/// can only change while the match is SCHEDULED (contract: 409 otherwise), so they are locked afterwards.
class MatchEditDialog extends ConsumerStatefulWidget {
  const MatchEditDialog({super.key, required this.match, required this.save});
  final gen.Match match;
  final Future<void> Function(MatchEdit edit) save;

  @override
  ConsumerState<MatchEditDialog> createState() => _MatchEditDialogState();
}

class _MatchEditDialogState extends ConsumerState<MatchEditDialog> {
  final _form = GlobalKey<FormState>();
  late final _opponent = TextEditingController(text: widget.match.opponentName);
  late final _venue = TextEditingController(text: widget.match.venue ?? '');
  late final _periods = TextEditingController(
    text: '${widget.match.periodCount}',
  );
  late final _minutes = TextEditingController(
    text: '${widget.match.periodMinutes}',
  );
  late gen.HomeAway _homeAway = widget.match.homeAway;
  late final DateTime _wall = ref
      .read(tenantZoneProvider)
      .wall(widget.match.scheduledAt);
  late DateTime _date = DateTime(_wall.year, _wall.month, _wall.day);
  late TimeOfDay _time = TimeOfDay(hour: _wall.hour, minute: _wall.minute);

  bool get _periodsEditable => widget.match.status == gen.MatchStatus.SCHEDULED;

  @override
  void dispose() {
    _opponent.dispose();
    _venue.dispose();
    _periods.dispose();
    _minutes.dispose();
    super.dispose();
  }

  String? _intIn(AppLocalizations l, String? v, int max) {
    final n = int.tryParse((v ?? '').trim());
    return n == null || n < 1 || n > max ? l.fieldInvalidNumber : null;
  }

  MatchEdit _edit() {
    final venue = _venue.text.trim();
    return (
      opponentName: _opponent.text.trim(),
      scheduledAt: ref
          .read(tenantZoneProvider)
          .instant(
            DateTime(
              _date.year,
              _date.month,
              _date.day,
              _time.hour,
              _time.minute,
            ),
          ),
      homeAway: _homeAway,
      venue: venue.isEmpty ? null : venue,
      periodCount: _periodsEditable ? int.parse(_periods.text.trim()) : null,
      periodMinutes: _periodsEditable ? int.parse(_minutes.text.trim()) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormDialog(
      title: l.matchEdit,
      formKey: _form,
      onSubmit: () => runAction(
        context,
        () => widget.save(_edit()),
        success: l.matchUpdated,
      ),
      children: [
        TextFormField(
          key: const Key('match-edit-opponent'),
          controller: _opponent,
          decoration: InputDecoration(labelText: l.matchOpponent),
          validator: (v) => requiredValidator(l, v),
        ),
        formGap,
        SegmentedButton<gen.HomeAway>(
          segments: [
            ButtonSegment(value: gen.HomeAway.HOME, label: Text(l.matchHome)),
            ButtonSegment(value: gen.HomeAway.AWAY, label: Text(l.matchAway)),
          ],
          selected: {_homeAway},
          onSelectionChanged: (s) => setState(() => _homeAway = s.single),
        ),
        formGap,
        DateField(
          key: const Key('match-edit-date'),
          label: l.matchDate,
          value: _date,
          onChanged: (d) => setState(() => _date = d),
        ),
        formGap,
        InkWell(
          key: const Key('match-edit-time'),
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: _time,
            );
            if (t != null) setState(() => _time = t);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l.matchTime,
              suffixIcon: const Icon(Icons.schedule),
            ),
            child: Text('${two(_time.hour)}:${two(_time.minute)}'),
          ),
        ),
        formGap,
        TextFormField(
          key: const Key('match-edit-venue'),
          controller: _venue,
          maxLength: 200,
          decoration: InputDecoration(labelText: l.matchVenue),
        ),
        TextFormField(
          key: const Key('match-edit-period-count'),
          controller: _periods,
          enabled: _periodsEditable,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.matchPeriodCount),
          validator: (v) => _periodsEditable ? _intIn(l, v, 8) : null,
        ),
        formGap,
        TextFormField(
          key: const Key('match-edit-period-minutes'),
          controller: _minutes,
          enabled: _periodsEditable,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.matchPeriodMinutes),
          validator: (v) => _periodsEditable ? _intIn(l, v, 60) : null,
        ),
      ],
    );
  }
}
