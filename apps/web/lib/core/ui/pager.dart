import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';

/// The page row under an open-ended list the server pages (ADR-0061): the previous and next chevrons around
/// "Page x of y", nothing while the list fits one page. [page] is 0-based; [onPage] gets the page asked for.
/// Keys `<keyPrefix>-previous` and `<keyPrefix>-next`.
class Pager extends StatelessWidget {
  const Pager({
    super.key,
    required this.keyPrefix,
    required this.page,
    required this.totalPages,
    required this.onPage,
  });

  final String keyPrefix;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: Key('$keyPrefix-previous'),
          tooltip: l.pagePrevious,
          icon: const Icon(Icons.chevron_left),
          onPressed: page > 0 ? () => onPage(page - 1) : null,
        ),
        Text(l.pageOf(page + 1, totalPages)),
        IconButton(
          key: Key('$keyPrefix-next'),
          tooltip: l.pageNext,
          icon: const Icon(Icons.chevron_right),
          onPressed: page + 1 < totalPages ? () => onPage(page + 1) : null,
        ),
      ],
    );
  }
}
