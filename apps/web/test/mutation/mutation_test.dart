import 'package:flutter_test/flutter_test.dart';

import '../../tool/mutation/mutation.dart';

List<String> _mutated(String source, {List<String> only = const []}) => [
  for (final m in findMutants(source, only: only)) applyMutant(source, m),
];

List<String> _operators(String source) => [
  for (final m in findMutants(source)) m.operator.name,
];

/// The Dart mutation tool (WP88, docs/quality/mutation.md): its operators,
/// regions, manifest, verdicts and score, without running flutter test.
void main() {
  group('tokenize', () {
    test('skips comments and strings, keeps code tokens with lines', () {
      final tokens = tokenize(
        "// a < b\nfinal s = 'x < \${a == 1} y'; /* 1 */\nif (a < 2) {}\n",
      );
      expect(tokens.map((t) => t.text), [
        'final',
        's',
        '=',
        "'x < \${a == 1} y'",
        ';',
        'if',
        '(',
        'a',
        '<',
        '2',
        ')',
        '{',
        '}',
      ]);
      expect(tokens.firstWhere((t) => t.text == '<').line, 3);
    });

    test('handles raw, triple-quoted and nested strings', () {
      final tokens = tokenize("r'\\\\'; '''a\n'b'\n'''; \"\${f('}')}\"; x");
      expect(tokens.where((t) => t.kind == TokenKind.string), hasLength(3));
      expect(tokens.last.text, 'x');
    });
  });

  group('operators', () {
    test('negate condition: if / while conditions, == and !=, prefix !', () {
      expect(_mutated('if (a) f();'), contains('if (!(a)) f();'));
      expect(_mutated('while (a < b) {}'), contains('while (!(a < b)) {}'));
      expect(_mutated('x = a == b;'), contains('x = a != b;'));
      expect(_mutated('x = a != b;'), contains('x = a == b;'));
      expect(_mutated('x = !a;'), contains('x = a;'));
      expect(_mutated('x = a!.b;'), isNot(contains('x = a.b;')));
    });

    test('a condition is not negated twice the same way', () {
      expect(
        _mutated('if (a == b) f();'),
        isNot(contains('if (!(a == b)) f();')),
      );
      expect(_mutated('if (!a.b) f();'), isNot(contains('if (!(!a.b)) f();')));
      expect(
        _mutated('if (a == b && c) f();'),
        contains('if (!(a == b && c)) f();'),
      );
    });

    test('swap comparison: boundaries and && / ||', () {
      expect(_mutated('x = a < b;'), contains('x = a <= b;'));
      expect(_mutated('x = a <= b;'), contains('x = a < b;'));
      expect(_mutated('x = a > b;'), contains('x = a >= b;'));
      expect(_mutated('x = a >= b;'), contains('x = a > b;'));
      expect(_mutated('x = a && b;'), contains('x = a || b;'));
      expect(_mutated('x = a || b;'), contains('x = a && b;'));
    });

    test('generics and type arguments are never comparisons', () {
      expect(
        _operators('final List<Map<String, int>> x = f<int>();'),
        isNot(contains('swapComparison')),
      );
    });

    test('boundary: an integer literal one up and one down', () {
      expect(_mutated('x = 3;'), containsAll(['x = 4;', 'x = 2;']));
      expect(_mutated('x = 0;'), containsAll(['x = 1;', 'x = (-1);']));
      expect(_operators('x = 0x1F + 1.5;'), isNot(contains('boundary')));
    });

    test('boolean literals flip', () {
      expect(_mutated('x = true;'), contains('x = false;'));
      expect(_mutated('x = false;'), contains('x = true;'));
    });

    test('remove statement: expression statements in code blocks only', () {
      const source = '''
class A {
  A(this.x);
  final int x;
  int get y => x;
  void f() {
    g();
    x.h(1, () {
      k();
    });
    final z = 1;
    return;
  }
}
''';
      final removed = [
        for (final m in findMutants(source))
          if (m.operator == MutationOperator.removeStatement) m.original,
      ];
      expect(removed, ['g();', 'x.h(1, () {\n      k();\n    });', 'k();']);
    });

    test('map and set literals hold no statements', () {
      expect(
        _operators("final m = {'a': f(), 'b': g()};"),
        isNot(contains('removeStatement')),
      );
    });
  });

  group('regions', () {
    const source = '''
int a(int x) => x + 1;

int b(int x) {
  return x - 2;
}

class C {
  bool get d => true;
}

final e = f((v) {
  return v * 3;
});
''';

    test('only the named top-level declarations are mutated', () {
      final lines = {
        for (final m in findMutants(source, only: ['b', 'e'])) m.line,
      };
      expect(lines, {4, 12});
    });

    test('a class is one region', () {
      expect(findMutants(source, only: ['C']).map((m) => m.line).toSet(), {8});
    });

    test('an unknown name is an error', () {
      expect(
        () => findMutants(source, only: ['nope']),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('manifest', () {
    test('reads targets, tests, regions, equivalents and the baseline', () {
      final manifest = Manifest.parse('''
{
  "baseline": 90,
  "timeoutFactor": 4,
  "targets": [
    {"file": "lib/a.dart", "tests": ["test/a_test.dart"], "only": ["f"]},
    {"file": "lib/b.dart", "tests": ["test/b_test.dart", "test/c_test.dart"]}
  ],
  "equivalent": [
    {"file": "lib/a.dart", "operator": "boundary", "line": "x = 3;",
     "replacement": "4", "reason": "any value above 2 works"}
  ]
}
''');
      expect(manifest.baseline, 90);
      expect(manifest.timeoutFactor, 4);
      expect(manifest.targets.map((t) => t.file), ['lib/a.dart', 'lib/b.dart']);
      expect(manifest.targets.first.only, ['f']);
      expect(manifest.targets.last.tests, hasLength(2));
      final mutant = findMutants('x = 3;')
          .firstWhere((m) => m.replacement == '4');
      expect(manifest.equivalentFor('lib/a.dart', mutant, 'x = 3;'), isNotNull);
      expect(manifest.equivalentFor('lib/b.dart', mutant, 'x = 3;'), isNull);
    });

    test('a target without tests is rejected', () {
      expect(
        () => Manifest.parse(
          '{"baseline": 1, "targets": [{"file": "lib/a.dart", "tests": []}]}',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('verdicts and score', () {
    test('a failing run kills, a passing one survives, a hang times out', () {
      expect(
        verdictOf(exitCode: 1, output: 'Some tests failed.'),
        Verdict.killed,
      );
      expect(
        verdictOf(exitCode: 0, output: 'All tests passed!'),
        Verdict.survived,
      );
      expect(
        verdictOf(exitCode: -9, output: '', timedOut: true),
        Verdict.timedOut,
      );
    });

    test('a mutant that does not compile is not viable', () {
      expect(
        verdictOf(
          exitCode: 1,
          output: 'Failed to load "test/a_test.dart": Compilation failed',
        ),
        Verdict.nonViable,
      );
      expect(
        verdictOf(exitCode: 1, output: 'lib/a.dart:3:7: Error: Expected'),
        Verdict.nonViable,
      );
    });

    test('the score counts killed and timed out over the viable mutants', () {
      final score = Score({
        Verdict.killed: 7,
        Verdict.timedOut: 1,
        Verdict.survived: 2,
        Verdict.nonViable: 5,
      });
      expect(score.detected, 8);
      expect(score.viable, 10);
      expect(score.percent, 80);
      expect(score.meets(80), isTrue);
      expect(score.meets(81), isFalse);
      expect(Score({}).percent, 100);
    });
  });
}
