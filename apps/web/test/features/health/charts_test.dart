import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/theme.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/ui/chart_tokens.dart';
import 'package:hoops_app/features/health/presentation/charts.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';

Widget _host(
  Widget child, {
  Brightness brightness = Brightness.light,
  String locale = 'es',
}) => MaterialApp(
  theme: buildTheme(brightness),
  locale: Locale(locale),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

final _sample = [
  ChartPoint(DateTime.utc(2026, 1, 10), 140),
  ChartPoint(DateTime.utc(2026, 6, 10), 144),
  ChartPoint(DateTime.utc(2026, 10, 10), 148),
];

void main() {
  group('GrowthChart', () {
    testWidgets(
      'renders a line chart with title, semantics summary and a table toggle',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(GrowthChart(title: 'Altura (cm)', points: _sample)),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(LineChart), findsOneWidget);
        expect(find.text('Altura (cm)'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            RegExp(r'Gráfico de Altura \(cm\): 3 medidas, la última 148'),
          ),
          findsOneWidget,
        );
        expect(find.text('Ver tabla'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('table view lists every value, newest first', (tester) async {
      await tester.pumpWidget(
        _host(GrowthChart(title: 'Altura (cm)', points: _sample)),
      );
      await tester.tap(find.text('Ver tabla'));
      await tester.pumpAndSettle();
      final cells = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(DataTable),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      expect(cells.sublist(cells.length - 6), [
        '10/10/26',
        '148',
        '10/06/26',
        '144',
        '10/01/26',
        '140',
      ]);
    });

    testWidgets('a single point and an empty series do not throw', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          GrowthChart(
            title: 'Peso (kg)',
            points: [ChartPoint(DateTime.utc(2026, 5, 1), 40)],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(LineChart), findsOneWidget);
      await tester.pumpWidget(
        _host(const GrowthChart(title: 'Peso (kg)', points: [])),
      );
      expect(find.text('Sin datos para el gráfico'), findsWidgets);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('dark theme renders with the dark series colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          GrowthChart(title: 'Altura (cm)', points: _sample),
          brightness: Brightness.dark,
        ),
      );
      expect(tester.takeException(), isNull);
      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      expect(data.lineBarsData.single.color, ChartPalette.dark.series);
      expect(data.lineBarsData.single.barWidth, 2);
    });

    testWidgets(
      'marker radius is at least 4 (>= 8 px marks) with a surface ring',
      (tester) async {
        await tester.pumpWidget(
          _host(GrowthChart(title: 'Altura (cm)', points: _sample)),
        );
        final bar = tester
            .widget<LineChart>(find.byType(LineChart))
            .data
            .lineBarsData
            .single;
        final painter = bar.dotData.getDotPainter(
          bar.spots.first,
          0,
          bar,
          0,
        ) as FlDotCirclePainter;
        expect(painter.radius * 2, greaterThanOrEqualTo(8));
        expect(painter.strokeWidth, 2);
        expect(painter.strokeColor, ChartPalette.light.surface);
      },
    );
  });

  group('BandHistoryChart', () {
    final points = [
      ChartPoint(
        DateTime.utc(2026, 3, 1),
        28,
        band: ath.NormBand.BELOW_AVERAGE,
      ),
      ChartPoint(
        DateTime.utc(2026, 7, 1),
        34,
        band: ath.NormBand.AVERAGE,
        pending: true,
      ),
      ChartPoint(DateTime.utc(2026, 10, 1), 46, band: ath.NormBand.EXCELLENT),
      ChartPoint(DateTime.utc(2026, 11, 1), 47),
    ];

    testWidgets(
      'renders with a legend naming the five bands and the no-norm marker',
      (tester) async {
        await tester.pumpWidget(
          _host(
            BandHistoryChart(
              title: 'Salto vertical',
              unit: 'cm',
              points: points,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(LineChart), findsOneWidget);
        for (final label in [
          'Muy bajo',
          'Bajo la media',
          'Medio',
          'Sobre la media',
          'Excelente',
        ]) {
          expect(
            find.descendant(
              of: find.byKey(const Key('band-legend')),
              matching: find.text(label),
            ),
            findsOneWidget,
            reason: label,
          );
        }
        expect(find.text('Salto vertical (cm)'), findsOneWidget);
      },
    );

    testWidgets(
      'markers use the ordinal band ramp and hollow markers for results without a norm',
      (tester) async {
        await tester.pumpWidget(
          _host(
            BandHistoryChart(
              title: 'Salto vertical',
              unit: 'cm',
              points: points,
            ),
          ),
        );
        final bar = tester
            .widget<LineChart>(find.byType(LineChart))
            .data
            .lineBarsData
            .single;
        Color colorAt(int i) => (bar.dotData.getDotPainter(
          bar.spots[i],
          0,
          bar,
          i,
        ) as FlDotCirclePainter).color;
        expect(colorAt(0), ChartPalette.light.bands[1]);
        expect(colorAt(1), ChartPalette.light.bands[2]);
        expect(colorAt(2), ChartPalette.light.bands[4]);
        expect(colorAt(3), ChartPalette.light.surface);
      },
    );

    testWidgets(
      'band colouring is consistent between light and dark (same index, same band)',
      (tester) async {
        expect(ChartPalette.light.bands.length, 5);
        expect(ChartPalette.dark.bands.length, 5);
        await tester.pumpWidget(
          _host(
            BandHistoryChart(title: 'S', unit: 'cm', points: points),
            brightness: Brightness.dark,
          ),
        );
        final bar = tester
            .widget<LineChart>(find.byType(LineChart))
            .data
            .lineBarsData
            .single;
        expect(
          (bar.dotData.getDotPainter(
            bar.spots[2],
            0,
            bar,
            2,
          ) as FlDotCirclePainter).color,
          ChartPalette.dark.bands[4],
        );
      },
    );

    testWidgets('labels in English and Indonesian', (tester) async {
      await tester.pumpWidget(
        _host(
          BandHistoryChart(title: 'Jump', unit: 'cm', points: points),
          locale: 'en',
        ),
      );
      expect(find.text('Below average'), findsOneWidget);
      await tester.pumpWidget(
        _host(
          BandHistoryChart(title: 'Jump', unit: 'cm', points: points),
          locale: 'id',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sangat baik'), findsOneWidget);
    });

    testWidgets('empty series', (tester) async {
      await tester.pumpWidget(
        _host(const BandHistoryChart(title: 'Salto', unit: 'cm', points: [])),
      );
      expect(find.text('Sin datos para el gráfico'), findsWidgets);
    });
  });

  test('ordinal band ramps are strictly lighter-to-darker (lightness monotone) in both modes', () {
    double lightness(Color c) => HSLColor.fromColor(c).lightness;
    for (final palette in [ChartPalette.light, ChartPalette.dark]) {
      final l = palette.bands.map(lightness).toList();
      for (var i = 1; i < l.length; i++) {
        expect(l[i], lessThan(l[i - 1]), reason: 'step $i');
      }
    }
  });
}
