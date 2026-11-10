import 'package:flutter/material.dart';

import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The fields of an exercise wherever one is written, a plan item or a
/// catalogue exercise: title, description, duration, sets, repetitions and a
/// video link. Owns its controllers ([dispose] them with the form).
class ExerciseFields {
  ExerciseFields({
    String? title,
    String? description,
    int? minutes,
    int? sets,
    int? repetitions,
    String? videoUrl,
  }) : _title = TextEditingController(text: title),
       _description = TextEditingController(text: description),
       _minutes = TextEditingController(text: minutes?.toString()),
       _sets = TextEditingController(text: sets?.toString()),
       _repetitions = TextEditingController(text: repetitions?.toString()),
       _video = TextEditingController(text: videoUrl);

  final TextEditingController _title;
  final TextEditingController _description;
  final TextEditingController _minutes;
  final TextEditingController _sets;
  final TextEditingController _repetitions;
  final TextEditingController _video;

  String get title => _title.text.trim();
  String? get description => _text(_description);
  int? get minutes => _int(_minutes);
  int? get sets => _int(_sets);
  int? get repetitions => _int(_repetitions);
  String? get videoUrl => _text(_video);

  static int? _int(TextEditingController c) => int.tryParse(c.text.trim());
  static String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void dispose() {
    for (final c in [
      _title,
      _description,
      _minutes,
      _sets,
      _repetitions,
      _video,
    ]) {
      c.dispose();
    }
  }

  static String? _optionalCount(AppLocalizations l, String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    final n = int.tryParse(v!.trim());
    return n == null || n < 1 ? l.fieldInvalidNumber : null;
  }

  /// The form fields; their keys start with [keyPrefix] (`item-title`, …).
  List<Widget> build(AppLocalizations l, {required String keyPrefix}) {
    Widget count(String key, TextEditingController c, String label) => Expanded(
      child: TextFormField(
        key: Key('$keyPrefix-$key'),
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (v) => _optionalCount(l, v),
      ),
    );
    return [
      TextFormField(
        key: Key('$keyPrefix-title'),
        controller: _title,
        decoration: InputDecoration(labelText: l.planItemTitle),
        validator: (v) => requiredValidator(l, v),
      ),
      formGap,
      TextFormField(
        key: Key('$keyPrefix-description'),
        controller: _description,
        maxLines: 2,
        decoration: InputDecoration(labelText: l.planDescription),
      ),
      formGap,
      Row(
        children: [
          count('duration', _minutes, l.planItemDuration),
          const SizedBox(width: HoopsSpace.sm),
          count('sets', _sets, l.planItemSets),
          const SizedBox(width: HoopsSpace.sm),
          count('reps', _repetitions, l.planItemReps),
        ],
      ),
      formGap,
      TextFormField(
        key: Key('$keyPrefix-video'),
        controller: _video,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(labelText: l.planItemVideo),
        validator: (v) =>
            (v ?? '').trim().isEmpty || v!.trim().startsWith('https://')
            ? null
            : l.planItemVideoInvalid,
      ),
    ];
  }
}

/// The description and the video link of an exercise.
class ExerciseInfo extends StatelessWidget {
  const ExerciseInfo({super.key, this.description, this.videoUrl});
  final String? description;
  final String? videoUrl;

  @override
  Widget build(BuildContext context) {
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.xs,
      children: [
        if (description != null) Text(description!),
        if (videoUrl != null)
          Row(
            spacing: HoopsSpace.xs,
            children: [
              Icon(Icons.play_circle_outline, color: c.brand),
              Expanded(
                child: SelectableText(
                  videoUrl!,
                  style: text.bodySmall!.copyWith(color: c.accentText),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Marks an item copied from a catalogue exercise (it has an `exerciseId`).
class CatalogueMarker extends StatelessWidget {
  const CatalogueMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Tooltip(
      message: l.exerciseFromCatalogue,
      child: Icon(
        Icons.menu_book_outlined,
        size: HoopsSpace.md + HoopsSpace.xs,
        color: HoopsTokens.colorsOf(context).inkMuted,
        semanticLabel: l.exerciseFromCatalogue,
      ),
    );
  }
}
