import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../connectivity/connectivity_providers.dart';
import '../errors/app_error.dart';
import '../ui/app_error_view.dart';
import '../ui/kit.dart';
import 'export_context.dart';
import 'export_file_name.dart';
import 'export_runner.dart';

/// The server's answer when an export would exceed the row limit (core 3.5.0).
const exportTooLargeCode = 'EXPORT_TOO_LARGE';

/// Asks the server for a CSV file in the given language (`es`, `en`, `id`).
typedef FetchServerCsv = Future<Uint8List> Function(String language);

/// An export button for a file the *server* builds (roster, audit trail): it
/// fetches the bytes in the app's language and hands them to the browser under
/// the shared file-name rule. The file is made on the server, so offline the
/// button is disabled and says why. A Problem is shown like on other screens;
/// the row limit asks the person to narrow the filters.
class ServerCsvExportButton extends ConsumerStatefulWidget {
  const ServerCsvExportButton({
    super.key,
    required this.what,
    required this.tooltip,
    required this.fetch,
    this.slug,
  });

  /// The middle part of the file name (`roster mini a`, `audit`).
  final String what;
  final String tooltip;
  final FetchServerCsv fetch;

  /// The academy slug of the file name; the active academy's when null.
  final String? slug;

  @override
  ConsumerState<ServerCsvExportButton> createState() =>
      _ServerCsvExportButtonState();
}

class _ServerCsvExportButtonState extends ConsumerState<ServerCsvExportButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final online = ref.watch(onlineProvider).value ?? true;
    return IconButton(
      tooltip: online ? widget.tooltip : l.exportNeedsConnection,
      icon: _busy
          ? const SizedBox.square(
              dimension: HoopsSpace.lg,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.file_download_outlined),
      onPressed: online && !_busy ? () => _export(context) : null,
    );
  }

  Future<void> _export(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final language = Localizations.localeOf(context).languageCode;
    setState(() => _busy = true);
    try {
      final bytes = await widget.fetch(language);
      final name = exportFileName(
        slug: widget.slug ?? ref.read(academySlugProvider),
        what: widget.what,
        date: exportDay(ref),
        extension: 'csv',
      );
      ref
          .read(fileDownloaderProvider)
          .save(
            fileName: name,
            bytes: bytes,
            mediaType: 'text/csv; charset=utf-8',
          );
      _show(messenger, l.exportSaved(name));
    } on Object catch (e) {
      final error = AppError.of(e);
      _show(
        messenger,
        error.code == exportTooLargeCode ? l.exportTooLarge : error.message(l),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(ScaffoldMessengerState? messenger, String text) =>
      messenger?.showSnackBar(SnackBar(content: Text(text)));
}
