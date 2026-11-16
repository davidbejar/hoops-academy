import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../connectivity/connectivity_providers.dart';
import '../errors/app_error.dart';
import '../ui/app_error_view.dart';
import '../ui/kit.dart';
import 'export_context.dart';
import 'export_file_name.dart';
import 'export_runner.dart';
import 'server_csv_export.dart' show exportTooLargeCode;
import 'server_file.dart';

/// Asks the server for a PDF in the given language (`es`, `en`, `id`).
typedef FetchServerPdf = Future<ServerFile> Function(String language);

/// The 503 Problem code of a PDF the server could not render.
const upstreamUnavailableCode = 'UPSTREAM_UNAVAILABLE';

/// A button for a PDF the *server* prints (team roster, match sheet): it
/// fetches the bytes in the app's language and hands them to the browser under
/// the name the server gave (the shared file-name rule when it gave none).
/// Online only, like the other server exports. A 503 (pdf-service down) and a
/// 422 `EXPORT_TOO_LARGE` show their own message; any other Problem is shown
/// as on other screens.
class ServerPdfExportButton extends ConsumerStatefulWidget {
  const ServerPdfExportButton({
    super.key,
    required this.what,
    required this.tooltip,
    required this.fetch,
    required this.unavailableMessage,
    this.tooLargeMessage,
    this.slug,
  });

  /// The middle part of the fallback file name (`roster mini a`).
  final String what;
  final String tooltip;
  final FetchServerPdf fetch;

  /// Shown on a 503: try again later (and the CSV where there is one).
  final String unavailableMessage;

  /// Shown on a 422 `EXPORT_TOO_LARGE`; the generic message when null.
  final String? tooLargeMessage;
  final String? slug;

  @override
  ConsumerState<ServerPdfExportButton> createState() =>
      _ServerPdfExportButtonState();
}

class _ServerPdfExportButtonState extends ConsumerState<ServerPdfExportButton> {
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
          : const Icon(Icons.picture_as_pdf_outlined),
      onPressed: online && !_busy ? () => _export(context) : null,
    );
  }

  Future<void> _export(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final language = Localizations.localeOf(context).languageCode;
    setState(() => _busy = true);
    try {
      final file = await widget.fetch(language);
      final name =
          file.fileName ??
          exportFileName(
            slug: widget.slug ?? ref.read(academySlugProvider),
            what: widget.what,
            date: exportDay(ref),
            extension: 'pdf',
          );
      ref
          .read(fileDownloaderProvider)
          .save(
            fileName: name,
            bytes: file.bytes,
            mediaType: 'application/pdf',
          );
      _show(messenger, l.exportSaved(name));
    } on Object catch (e) {
      _show(messenger, _messageFor(AppError.of(e), l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(AppError error, AppLocalizations l) {
    if (error.code == upstreamUnavailableCode || error.status == 503) {
      return widget.unavailableMessage;
    }
    if (error.code == exportTooLargeCode && widget.tooLargeMessage != null) {
      return widget.tooLargeMessage!;
    }
    return error.message(l);
  }

  void _show(ScaffoldMessengerState? messenger, String text) =>
      messenger?.showSnackBar(SnackBar(content: Text(text)));
}
