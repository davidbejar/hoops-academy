import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/export/export_context.dart';
import 'package:hoops_app/core/export/export_runner.dart';

import 'fake_export.dart';

/// 10 Nov 2026, so every export is named `...-20261110.<ext>`.
final exportDayUtc = DateTime.utc(2026, 11, 10, 10);

/// Browser download and Excel library replaced by fakes; the clock pinned.
List<Override> exportOverrides(
  FakeFileDownloader downloader, {
  bool excelOffline = false,
}) => [
  fileDownloaderProvider.overrideWithValue(downloader),
  xlsxBuilderProvider.overrideWithValue(fakeXlsx(offline: excelOffline)),
  exportClockProvider.overrideWithValue(() => exportDayUtc),
];
