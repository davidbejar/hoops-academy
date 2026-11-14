import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/kit.dart';

import '../support/kit_harness.dart';

/// Light and dark goldens of every kit widget (WP72, ADR-0040).
/// Regenerate with `flutter test --update-goldens test/golden`.
void main() {
  final cases = <String, (Size, Widget Function())>{
    'status_chip': (
      const Size(360, 120),
      () => const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatusChip('Programado'),
          StatusChip('En juego', tone: HoopsTone.accent, dot: true),
          StatusChip('Finalizado', tone: HoopsTone.success),
          StatusChip('Moderada', tone: HoopsTone.warning),
          StatusChip('Lesionado', tone: HoopsTone.danger, icon: Icons.healing),
          StatusChip('Entrenador', tone: HoopsTone.info),
        ],
      ),
    ),
    'list_row': (
      const Size(360, 240),
      () => Column(
        children: [
          ListRow(
            title: 'Ana Ruiz',
            subtitle: 'Mini A · #7',
            leading: const InitialsAvatar(name: 'Ana Ruiz'),
            onTap: () {},
          ),
          const SizedBox(height: HoopsSpace.gap),
          const ListRow(
            title: 'Leo Gil',
            subtitle: 'Mini A · #10',
            leading: InitialsAvatar(name: 'Leo Gil', tone: HoopsTone.neutral),
            trailing: StatusChip('Lesionado', tone: HoopsTone.danger),
          ),
        ],
      ),
    ),
    'section_card': (
      const Size(360, 240),
      () => SectionCard(
        title: 'Lesiones',
        subtitle: '1 abierta',
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))],
        child: const Text('rodilla izquierda · regreso previsto 18/11'),
      ),
    ),
    'stat_tile': (
      const Size(360, 280),
      () => const ResponsiveGrid(
        minTileWidth: 140,
        children: [
          StatTile(
            label: 'Asistencia',
            value: '92 %',
            icon: Icons.event_available,
            caption: '+4 vs. octubre',
            tone: HoopsTone.success,
          ),
          StatTile(label: 'Jugadores', value: '42', icon: Icons.groups),
        ],
      ),
    ),
    'empty_state': (
      const Size(360, 360),
      () => EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Sin entrenamientos',
        message: 'Crea la primera sesión de la semana.',
        action: FilledButton(onPressed: () {}, child: const Text('Nueva')),
      ),
    ),
    'notice_banner': (
      const Size(360, 200),
      () => Column(
        children: [
          const NoticeBanner(
            message: 'Modo demo: datos de ejemplo',
            icon: Icons.science_outlined,
          ),
          const NoticeBanner(
            message: 'Sin conexión',
            tone: HoopsTone.warning,
            icon: Icons.cloud_off,
          ),
          NoticeBanner(
            message: 'Nueva versión',
            tone: HoopsTone.info,
            icon: Icons.system_update_alt,
            action: TextButton(onPressed: () {}, child: const Text('Recargar')),
          ),
        ],
      ),
    ),
    'page_header': (
      const Size(360, 240),
      () => PageHeader(
        eyebrow: 'Temporada 2026/27',
        title: 'Equipos',
        subtitle: '3 equipos',
        actions: [
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Nuevo equipo'),
          ),
          OutlinedButton(onPressed: () {}, child: const Text('Casos')),
        ],
      ),
    ),
    'icon_tile': (
      const Size(360, 120),
      () => const Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          IconTile(Icons.history),
          IconTile(Icons.business_outlined, tone: HoopsTone.info),
          IconTile(Icons.check_circle_outline, tone: HoopsTone.success),
          IconTile(Icons.warning_amber_rounded, tone: HoopsTone.warning),
          IconTile(Icons.block, tone: HoopsTone.danger, size: 56),
        ],
      ),
    ),
  };

  for (final MapEntry(key: name, value: (size, build)) in cases.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('$name, ${brightness.name}', (tester) async {
        await pumpKit(tester, build(), brightness: brightness, size: size);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/kit/${name}_${brightness.name}.png'),
        );
      });
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('form_dialog, ${brightness.name}', (tester) async {
      await pumpKit(
        tester,
        Builder(
          builder: (context) => TextButton(
            key: const Key('open'),
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => FormDialog(
                title: 'Nuevo equipo',
                formKey: GlobalKey<FormState>(),
                onSubmit: () async => true,
                children: const [
                  TextField(decoration: InputDecoration(labelText: 'Nombre')),
                  formGap,
                  TextField(
                    decoration: InputDecoration(labelText: 'Categoría'),
                  ),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
        size: const Size(360, 480),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/kit/form_dialog_${brightness.name}.png'),
      );
    });

    testWidgets('action_sheet, ${brightness.name}', (tester) async {
      await pumpKit(
        tester,
        Builder(
          builder: (context) => TextButton(
            key: const Key('open'),
            onPressed: () => showActionSheet<String>(
              context,
              title: 'Jugada',
              actions: const [
                SheetAction(icon: Icons.add, label: 'Canasta', value: 'two'),
                SheetAction(
                  icon: Icons.sports,
                  label: 'Falta',
                  value: 'foul',
                  subtitle: 'Personal',
                ),
                SheetAction(
                  icon: Icons.undo,
                  label: 'Anular',
                  value: 'void',
                  destructive: true,
                ),
              ],
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
        size: const Size(360, 480),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/kit/action_sheet_${brightness.name}.png'),
      );
    });
  }
}
