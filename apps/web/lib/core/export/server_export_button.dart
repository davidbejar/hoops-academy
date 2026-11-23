import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../connectivity/connectivity_providers.dart';
import '../errors/app_error.dart';
import '../ui/app_error_view.dart';
import 'busy_icon_button.dart';
import 'export_context.dart';
import 'export_file_name.dart';
import 'export_runner.dart';
import 'server_file.dart';

/// The server's answer when an export would exceed the row limit (core 3.5.0).
const exportTooLargeCode = 'EXPORT_TOO_LARGE';

/// The 503 Problem code of a PDF the server could not render.
const upstreamUnavailableCode = 'UPSTREAM_UNAVAILABLE';

/// Asks the server for a CSV file in the given language (`es`, `en`, `id`).
typedef FetchServerCsv = Future<Uint8List> Function(String language);

/// Asks the server for a file (a PDF) in the given language.
typedef FetchServerFile = Future<ServerFile> Function(String language);

/// An export button for a file the *server* builds (roster, audit trail, dues
/// as CSV; team roster and match sheet as PDF): it fetches the bytes in the
/// app's language and hands them to the browser under the name the server gave
/// (the shared file-name rule when it gave none). The file is made on the
/// server, so offline the button is disabled and says why. One handling of
/// failures: `EXPORT_TOO_LARGE` asks to narrow the request ([tooLargeMessage]
/// or the generic text), a 503 (pdf-service down) shows [unavailableMessage],
/// any other Problem is shown as on other screens.
class ServerExportButton extends ConsumerStatefulWidget {
  const ServerExportButton._({
    super.key,
    required this.what,
    required this.tooltip,
    required this.icon,
    required this.extension,
    required this.mediaType,
    required this.fetch,
    this.slug,
    this.unavailableMessage,
    this.tooLargeMessage,
  });

  /// A CSV the server builds; [what] is the middle part of the file name
  /// (`roster mini a`, `audit`); [slug] the academy's, the active academy's
  /// when null.
  factory ServerExportButton.csv({
    Key? key,
    required String what,
    required String tooltip,
    required FetchServerCsv fetch,
    String? slug,
  }) => ServerExportButton._(
    key: key,
    what: what,
    tooltip: tooltip,
    icon: Icons.file_download_outlined,
    extension: 'csv',
    mediaType: 'text/csv; charset=utf-8',
    fetch: (language) async => ServerFile(await fetch(language)),
    slug: slug,
  );

  /// A PDF the server prints; [unavailableMessage] is shown on a 503 (try
  /// again later, and the CSV where there is one).
  factory ServerExportButton.pdf({
    Key? key,
    required String what,
    required String tooltip,
    required FetchServerFile fetch,
    required String unavailableMessage,
    String? tooLargeMessage,
    String? slug,
  }) => ServerExportButton._(
    key: key,
    what: what,
    tooltip: tooltip,
    icon: Icons.picture_as_pdf_outlined,
    extension: 'pdf',
    mediaType: 'application/pdf',
    fetch: fetch,
    slug: slug,
    unavailableMessage: unavailableMessage,
    tooLargeMessage: tooLargeMessage,
  );

  final String what;
  final String tooltip;
  final IconData icon;
  final String extension;
  final String mediaType;
  final FetchServerFile fetch;
  final String? slug;
  final String? unavailableMessage;
  final String? tooLargeMessage;

  @override
  ConsumerState<ServerExportButton> createState() => _ServerExportButtonState();
}

class _ServerExportButtonState extends ConsumerState<ServerExportButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final online = ref.watch(onlineProvider).value ?? true;
    return BusyIconButton(
      icon: widget.icon,
      busy: _busy,
      tooltip: online ? widget.tooltip : l.exportNeedsConnection,
      onPressed: online ? () => _export(context) : null,
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
            extension: widget.extension,
          );
      ref
          .read(fileDownloaderProvider)
          .save(fileName: name, bytes: file.bytes, mediaType: widget.mediaType);
      showExportMessage(messenger, l.exportSaved(name));
    } on Object catch (e) {
      showExportMessage(messenger, _messageFor(AppError.of(e), l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(AppError error, AppLocalizations l) {
    if (error.code == exportTooLargeCode) {
      return widget.tooLargeMessage ?? l.exportTooLarge;
    }
    if (widget.unavailableMessage != null &&
        (error.code == upstreamUnavailableCode || error.status == 503)) {
      return widget.unavailableMessage!;
    }
    return error.message(l);
  }
}
