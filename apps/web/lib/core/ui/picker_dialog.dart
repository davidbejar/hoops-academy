import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../design/tokens.dart';
import 'actions.dart';

/// A dialog that lists the options a [future] loads and closes on a tap in
/// one of them ("assign to a team", "pick a player"): a spinner while it
/// loads, the error message, [emptyText] when there are no options, else the
/// rows [itemBuilder] makes (usually a `ListTile` / `ListRow`). The close
/// button is built in.
///
/// [header] (a search field, say) sits above the list; a dialog with a
/// [height] scrolls the list inside it, one without grows to its rows.
class PickerDialog<T> extends StatelessWidget {
  const PickerDialog({
    super.key,
    required this.title,
    required this.future,
    required this.itemBuilder,
    required this.emptyText,
    this.emptyKey,
    this.intro,
    this.header,
    this.height,
  });

  final String title;
  final Future<List<T>> future;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyText;
  final Key? emptyKey;

  /// One line above the options.
  final String? intro;
  final Widget? header;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: HoopsSize.pickerWidth,
        height: height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?header,
            Flexible(
              child: FutureBuilder<List<T>>(
                future: future,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text(AppErrorText.of(snap.error!, l));
                  }
                  final items = snap.data;
                  if (items == null) {
                    return const SizedBox(
                      height: HoopsSpace.xxxl,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (items.isEmpty) return Text(emptyText, key: emptyKey);
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      if (intro != null) Text(intro!),
                      for (final item in items) itemBuilder(context, item),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  }
}
