import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../errors/app_error.dart';
import '../ui/app_error_view.dart';
import '../ui/kit.dart';
import 'busy_icon_button.dart';
import 'export_runner.dart';

/// Builds what a screen exports, at the moment the person picks a format.
typedef PrepareExport = Future<ExportJob> Function(
  WidgetRef ref,
  AppLocalizations l,
);

/// The export button of a screen: an icon that opens the kit's action sheet
/// with the formats the screen offers (CSV, Excel, Calendar). Excel is built
/// from a library fetched only now (decision 69); when it cannot be fetched
/// the person is told and CSV stays available.
class ExportMenu extends ConsumerStatefulWidget {
  const ExportMenu({super.key, required this.formats, required this.prepare});

  final List<ExportFormat> formats;
  final PrepareExport prepare;

  @override
  ConsumerState<ExportMenu> createState() => _ExportMenuState();
}

class _ExportMenuState extends ConsumerState<ExportMenu> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BusyIconButton(
      key: const Key('export-menu'),
      icon: Icons.file_download_outlined,
      busy: _busy,
      tooltip: l.exportTooltip,
      onPressed: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final format = await showActionSheet<ExportFormat>(
      context,
      title: l.exportTooltip,
      actions: [
        for (final f in widget.formats)
          SheetAction(
            key: Key('export-${f.name}'),
            icon: _icon(f),
            label: _label(l, f),
            value: f,
          ),
      ],
    );
    if (format == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final job = await widget.prepare(ref, l);
      final outcome = await ref.read(exportRunnerProvider).run(format, job);
      showExportMessage(messenger, switch (outcome) {
        ExportSaved(:final fileName) => [
          l.exportSaved(fileName),
          if (job.notice != null) job.notice!,
        ].join('\n'),
        ExportExcelUnavailable() => l.exportExcelUnavailable,
      });
    } on NothingToExport {
      showExportMessage(messenger, l.exportNothing);
    } on Object catch (e) {
      showExportMessage(messenger, AppError.of(e).message(l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static IconData _icon(ExportFormat f) => switch (f) {
    ExportFormat.csv => Icons.description_outlined,
    ExportFormat.xlsx => Icons.grid_on_outlined,
    ExportFormat.ics => Icons.event_outlined,
  };

  static String _label(AppLocalizations l, ExportFormat f) => switch (f) {
    ExportFormat.csv => l.exportCsv,
    ExportFormat.xlsx => l.exportExcel,
    ExportFormat.ics => l.exportCalendar,
  };
}
