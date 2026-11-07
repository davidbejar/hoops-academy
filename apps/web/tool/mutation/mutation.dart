// The pure part of the Dart mutation tool (WP88, docs/quality/mutation.md):
// a small Dart lexer, the mutation operators, declaration regions, the
// manifest, the verdict of one test run and the score. `run.dart` applies the
// mutants and runs `flutter test`; this library is unit tested in
// test/mutation/mutation_test.dart.
import 'dart:convert';

enum TokenKind { identifier, number, string, operator }

/// One code token; comments are skipped and a string (with its
/// interpolations) is a single opaque token.
class Token {
  const Token(this.kind, this.text, this.offset, this.line);

  final TokenKind kind;
  final String text;
  final int offset;
  final int line;

  int get end => offset + text.length;
}

const _operators = [
  '>>>=', '...?', '>>=', '<<=', '>>>', '??=', '...', '?..', '~/=', //
  '==', '!=', '<=', '>=', '&&', '||', '=>', '++', '--', '+=', '-=', '*=',
  '/=', '%=', '&=', '|=', '^=', '<<', '>>', '?.', '??', '..', '~/',
];

bool _isIdentifierStart(String c) => RegExp(r'[A-Za-z_$]').hasMatch(c);
bool _isIdentifierPart(String c) => RegExp(r'[A-Za-z0-9_$]').hasMatch(c);
bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

/// Splits Dart [source] into code tokens.
List<Token> tokenize(String source) => _Lexer(source).tokens();

class _Lexer {
  _Lexer(this.source);

  final String source;
  int _pos = 0;

  int get _length => source.length;
  String _at(int i) => i < _length ? source[i] : '';

  List<Token> tokens() {
    final tokens = <Token>[];
    while (_pos < _length) {
      final c = source[_pos];
      if (c.trim().isEmpty) {
        _pos++;
      } else if (source.startsWith('//', _pos)) {
        while (_pos < _length && source[_pos] != '\n') {
          _pos++;
        }
      } else if (source.startsWith('/*', _pos)) {
        _skipBlockComment();
      } else if (_stringStartsAt(_pos)) {
        final start = _pos;
        _skipString();
        tokens.add(_token(TokenKind.string, start));
      } else if (_isIdentifierStart(c)) {
        final start = _pos;
        while (_pos < _length && _isIdentifierPart(source[_pos])) {
          _pos++;
        }
        tokens.add(_token(TokenKind.identifier, start));
      } else if (_isDigit(c) || (c == '.' && _isDigit(_at(_pos + 1)))) {
        final start = _pos;
        _skipNumber();
        tokens.add(_token(TokenKind.number, start));
      } else {
        final start = _pos;
        final op = _operators.firstWhere(
          (o) => source.startsWith(o, _pos),
          orElse: () => c,
        );
        _pos += op.length;
        tokens.add(_token(TokenKind.operator, start));
      }
    }
    return tokens;
  }

  Token _token(TokenKind kind, int start) => Token(
    kind,
    source.substring(start, _pos),
    start,
    '\n'.allMatches(source.substring(0, start)).length + 1,
  );

  bool _stringStartsAt(int i) {
    final c = _at(i);
    if (c == "'" || c == '"') return true;
    return c == 'r' &&
        (_at(i + 1) == "'" || _at(i + 1) == '"') &&
        (i == 0 || !_isIdentifierPart(source[i - 1]));
  }

  void _skipBlockComment() {
    var depth = 0;
    do {
      if (source.startsWith('/*', _pos)) {
        depth++;
        _pos += 2;
      } else if (source.startsWith('*/', _pos)) {
        depth--;
        _pos += 2;
      } else {
        _pos++;
      }
    } while (depth > 0 && _pos < _length);
  }

  void _skipNumber() {
    if (source.startsWith('0x', _pos) || source.startsWith('0X', _pos)) {
      _pos += 2;
      while (_pos < _length && RegExp('[0-9a-fA-F_]').hasMatch(source[_pos])) {
        _pos++;
      }
      return;
    }
    while (_pos < _length) {
      final c = source[_pos];
      final exponentSign =
          (c == '+' || c == '-') && 'eE'.contains(_at(_pos - 1));
      final fraction = c == '.' && _isDigit(_at(_pos + 1));
      if (_isDigit(c) || c == '_' || 'eE'.contains(c) || exponentSign) {
        _pos++;
      } else if (fraction) {
        _pos++;
      } else {
        return;
      }
    }
  }

  void _skipString() {
    final raw = source[_pos] == 'r';
    if (raw) _pos++;
    final quote = source[_pos];
    final triple = source.startsWith(quote * 3, _pos);
    final delimiter = triple ? quote * 3 : quote;
    _pos += delimiter.length;
    while (_pos < _length) {
      if (source.startsWith(delimiter, _pos)) {
        _pos += delimiter.length;
        return;
      }
      final c = source[_pos];
      if (!raw && c == r'\') {
        _pos += 2;
      } else if (!raw && source.startsWith(r'${', _pos)) {
        _pos += 2;
        _skipInterpolation();
      } else {
        _pos++;
      }
    }
  }

  /// Skips the code of `${...}` up to and including its closing brace.
  void _skipInterpolation() {
    var depth = 1;
    while (_pos < _length && depth > 0) {
      final c = source[_pos];
      if (_stringStartsAt(_pos)) {
        _skipString();
      } else if (source.startsWith('//', _pos)) {
        while (_pos < _length && source[_pos] != '\n') {
          _pos++;
        }
      } else if (source.startsWith('/*', _pos)) {
        _skipBlockComment();
      } else {
        if (c == '{') depth++;
        if (c == '}') depth--;
        _pos++;
      }
    }
  }
}

enum MutationOperator {
  /// `if (c)` / `while (c)` to `!(c)`, `==` and `!=` swapped, a prefix `!`
  /// removed.
  negateCondition,

  /// `<` and `<=`, `>` and `>=`, `&&` and `||` swapped.
  swapComparison,

  /// An expression statement replaced by an empty one.
  removeStatement,

  /// An integer literal one up and one down.
  boundary,

  /// `true` and `false` swapped.
  booleanFlip,
}

/// One change of the source: [original] at [offset] becomes [replacement].
class Mutant {
  const Mutant({
    required this.operator,
    required this.offset,
    required this.original,
    required this.replacement,
    required this.line,
  });

  final MutationOperator operator;
  final int offset;
  final String original;
  final String replacement;
  final int line;

  String get description =>
      '${operator.name}: ${_oneLine(original)} -> ${_oneLine(replacement)}';

  static String _oneLine(String text) {
    final first = text.split('\n').first.trim();
    return text.contains('\n') ? '$first …' : first;
  }
}

String applyMutant(String source, Mutant mutant) => source.replaceRange(
  mutant.offset,
  mutant.offset + mutant.original.length,
  mutant.replacement,
);

const _statementKeywords = {
  'abstract', 'as', 'assert', 'async', 'break', 'case', 'catch', 'class', //
  'const', 'continue', 'covariant', 'default', 'deferred', 'do', 'dynamic',
  'else', 'enum', 'export', 'extends', 'extension', 'external', 'factory',
  'final', 'finally', 'for', 'Function', 'get', 'if', 'implements', 'import',
  'in', 'interface', 'is', 'late', 'library', 'mixin', 'new', 'null', 'on',
  'operator', 'part', 'required', 'rethrow', 'return', 'sealed', 'set',
  'static', 'switch', 'throw', 'try', 'typedef', 'var', 'void', 'while',
  'with', 'yield', 'base', 'when',
};

/// Tokens after which a `{` opens a block of statements.
const _blockOpeners = {')', '{', '}', ';', 'else', 'try', 'finally', 'do'};
const _blockModifiers = {'async', 'sync', '*'};

/// Every mutant of [source]; with [only], those inside the named top-level
/// declarations.
List<Mutant> findMutants(String source, {List<String> only = const []}) {
  final tokens = tokenize(source);
  final regions = [for (final name in only) _region(source, tokens, name)];
  bool inScope(Mutant m) =>
      regions.isEmpty ||
      regions.any((r) => m.offset >= r.start && m.offset < r.end);
  final mutants = [
    ..._comparisonsAndLiterals(source, tokens),
    ..._conditions(source, tokens),
    ..._statements(source, tokens),
  ].where(inScope).toList()..sort((a, b) => a.offset.compareTo(b.offset));
  return mutants;
}

bool _spaced(String source, Token t) =>
    t.offset > 0 &&
    source[t.offset - 1].trim().isEmpty &&
    t.end < source.length &&
    source[t.end].trim().isEmpty;

Mutant _replace(MutationOperator op, Token t, String replacement) => Mutant(
  operator: op,
  offset: t.offset,
  original: t.text,
  replacement: replacement,
  line: t.line,
);

Iterable<Mutant> _comparisonsAndLiterals(
  String source,
  List<Token> tokens,
) sync* {
  const swaps = {
    '<': '<=',
    '<=': '<',
    '>': '>=',
    '>=': '>',
    '&&': '||',
    '||': '&&',
  };
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    if (t.kind == TokenKind.operator && _spaced(source, t)) {
      if (t.text == '==' || t.text == '!=') {
        yield _replace(
          MutationOperator.negateCondition,
          t,
          t.text == '==' ? '!=' : '==',
        );
      }
      final swapped = swaps[t.text];
      if (swapped != null) {
        yield _replace(MutationOperator.swapComparison, t, swapped);
      }
    }
    if (t.kind == TokenKind.operator && t.text == '!' && _isPrefix(source, t)) {
      yield _replace(MutationOperator.negateCondition, t, '');
    }
    if (t.kind == TokenKind.identifier &&
        (t.text == 'true' || t.text == 'false')) {
      yield _replace(
        MutationOperator.booleanFlip,
        t,
        t.text == 'true' ? 'false' : 'true',
      );
    }
    if (t.kind == TokenKind.number && RegExp(r'^[0-9]+$').hasMatch(t.text)) {
      final value = int.parse(t.text);
      yield _replace(MutationOperator.boundary, t, '${value + 1}');
      yield _replace(
        MutationOperator.boundary,
        t,
        value == 0 ? '(-1)' : '${value - 1}',
      );
    }
  }
}

/// A prefix `!` (logical not) as opposed to the postfix null assertion `x!`.
bool _isPrefix(String source, Token t) {
  if (t.offset == 0) return true;
  final before = source[t.offset - 1];
  return !(_isIdentifierPart(before) || before == ')' || before == ']');
}

Iterable<Mutant> _conditions(String source, List<Token> tokens) sync* {
  for (var i = 0; i + 1 < tokens.length; i++) {
    final keyword = tokens[i].text;
    if ((keyword != 'if' && keyword != 'while') || tokens[i + 1].text != '(') {
      continue;
    }
    final close = _matching(tokens, i + 1);
    if (close == null || close == i + 2) continue;
    final start = tokens[i + 2].offset;
    final end = tokens[close - 1].end;
    final condition = source.substring(start, end);
    if (_sameAsAnotherMutant(tokens.sublist(i + 2, close))) continue;
    yield Mutant(
      operator: MutationOperator.negateCondition,
      offset: start,
      original: condition,
      replacement: '!($condition)',
      line: tokens[i + 2].line,
    );
  }
}

/// `if (!a)` or `if (a == b)`: negating the whole condition is the same mutant
/// as removing its `!` or swapping its `==`.
bool _sameAsAnotherMutant(List<Token> condition) {
  final texts = condition.map((t) => t.text).toList();
  const connectives = {'&&', '||', '??', '?'};
  if (texts.any(connectives.contains)) return false;
  final equalities = texts.where((t) => t == '==' || t == '!=').length;
  final simpleNot =
      texts.first == '!' &&
      condition
          .skip(1)
          .every((t) => t.kind == TokenKind.identifier || t.text == '.');
  return equalities == 1 || simpleNot;
}

/// Index of the bracket closing the one at [open], or null.
int? _matching(List<Token> tokens, int open) {
  var depth = 0;
  for (var i = open; i < tokens.length; i++) {
    final text = tokens[i].text;
    if (text == '(' || text == '[' || text == '{') depth++;
    if (text == ')' || text == ']' || text == '}') depth--;
    if (depth == 0) return i;
  }
  return null;
}

Iterable<Mutant> _statements(String source, List<Token> tokens) sync* {
  // Kind of each open bracket: true for a `{` that holds statements.
  final open = <bool>[];
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    final previous = i == 0 ? null : tokens[i - 1];
    if (t.text == '{') {
      open.add(_opensBlock(tokens, i));
    } else if (t.text == '(' || t.text == '[') {
      open.add(false);
    } else if (t.text == '}' || t.text == ')' || t.text == ']') {
      if (open.isNotEmpty) open.removeLast();
    }
    final atStatementStart =
        previous != null &&
        open.isNotEmpty &&
        open.last &&
        t.text != '{' &&
        t.text != '}' &&
        (previous.text == '{' || previous.text == ';' || previous.text == '}');
    if (!atStatementStart || !_startsExpressionStatement(source, tokens, i)) {
      continue;
    }
    final end = _statementEnd(tokens, i);
    if (end == null) continue;
    yield Mutant(
      operator: MutationOperator.removeStatement,
      offset: t.offset,
      original: source.substring(t.offset, tokens[end].end),
      replacement: ';',
      line: t.line,
    );
  }
}

bool _opensBlock(List<Token> tokens, int brace) {
  var i = brace - 1;
  while (i >= 0 && _blockModifiers.contains(tokens[i].text)) {
    i--;
  }
  return i >= 0 && _blockOpeners.contains(tokens[i].text);
}

bool _startsExpressionStatement(String source, List<Token> tokens, int i) {
  final t = tokens[i];
  if (t.kind != TokenKind.identifier || _statementKeywords.contains(t.text)) {
    return false;
  }
  final next = i + 1 < tokens.length ? tokens[i + 1] : null;
  if (next == null) return false;
  // `Type name`, `Type<T> name`, `Type? name`: a declaration.
  if (next.kind == TokenKind.identifier) return false;
  if ((next.text == '<' || next.text == '?') &&
      next.offset == t.end &&
      !_spaced(source, next)) {
    return false;
  }
  return true;
}

/// The `;` ending the statement that starts at [start], or null when the
/// tokens leave the enclosing bracket first (a collection element, a case).
int? _statementEnd(List<Token> tokens, int start) {
  var depth = 0;
  for (var i = start; i < tokens.length; i++) {
    final text = tokens[i].text;
    if (text == '(' || text == '[' || text == '{') depth++;
    if (text == ')' || text == ']' || text == '}') depth--;
    if (depth < 0) return null;
    if (depth == 0 && (text == ',' || text == '=>')) return null;
    if (depth == 0 && text == ';') return i;
  }
  return null;
}

class _Region {
  const _Region(this.start, this.end);
  final int start;
  final int end;
}

/// The source range of the top-level declaration named [name].
_Region _region(String source, List<Token> tokens, String name) {
  final lineStart = RegExp(
    '^(?:[A-Za-z_][\\w<>?, ]*\\s+)?${RegExp.escape(name)}\\b',
    multiLine: true,
  );
  for (final match in lineStart.allMatches(source)) {
    final first = tokens.indexWhere((t) => t.offset >= match.start);
    if (first < 0 || tokens[first].offset != match.start) continue;
    final end = _declarationEnd(tokens, first);
    if (end != null) return _Region(match.start, tokens[end].end);
  }
  throw ArgumentError.value(name, 'only', 'no top-level declaration');
}

int? _declarationEnd(List<Token> tokens, int first) {
  var depth = 0;
  var expression = false;
  for (var i = first; i < tokens.length; i++) {
    final text = tokens[i].text;
    if (depth == 0 && (text == '=>' || text == '=')) expression = true;
    if (text == '(' || text == '[' || text == '{') depth++;
    if (text == ')' || text == ']' || text == '}') depth--;
    if (depth == 0 && text == ';') return i;
    if (depth == 0 && text == '}' && !expression) return i;
  }
  return null;
}

/// One rule file and the tests that must notice its mutants.
class Target {
  const Target({required this.file, required this.tests, this.only = const []});

  final String file;
  final List<String> tests;

  /// Top-level declarations to mutate (empty: the whole file).
  final List<String> only;
}

/// A mutant accepted as equivalent, with the reason.
class Equivalent {
  const Equivalent({
    required this.file,
    required this.operator,
    required this.line,
    required this.replacement,
    required this.reason,
  });

  final String file;
  final String operator;

  /// The trimmed source line the mutant changes.
  final String line;

  /// The replacement text of the mutant.
  final String replacement;
  final String reason;
}

/// `tool/mutation/manifest.json`: what to mutate, which tests run, the
/// accepted equivalents and the baseline score.
class Manifest {
  const Manifest({
    required this.baseline,
    required this.targets,
    this.equivalents = const [],
    this.timeoutFactor = 3,
  });

  factory Manifest.parse(String json) {
    final root = jsonDecode(json) as Map<String, dynamic>;
    List<String> strings(Object? list) => [
      for (final s in (list as List<dynamic>? ?? const [])) s as String,
    ];
    final targets = [
      for (final t in root['targets'] as List<dynamic>)
        Target(
          file: (t as Map<String, dynamic>)['file'] as String,
          tests: strings(t['tests']),
          only: strings(t['only']),
        ),
    ];
    for (final t in targets) {
      if (t.tests.isEmpty) {
        throw FormatException('${t.file} names no tests');
      }
    }
    return Manifest(
      baseline: root['baseline'] as int,
      timeoutFactor: root['timeoutFactor'] as int? ?? 3,
      targets: targets,
      equivalents: [
        for (final e in root['equivalent'] as List<dynamic>? ?? const [])
          Equivalent(
            file: (e as Map<String, dynamic>)['file'] as String,
            operator: e['operator'] as String,
            line: e['line'] as String,
            replacement: e['replacement'] as String,
            reason: e['reason'] as String,
          ),
      ],
    );
  }

  /// Minimum score in percent (rounded down) a run must reach.
  final int baseline;
  final List<Target> targets;
  final List<Equivalent> equivalents;

  /// A mutant's run may take this many times the unmutated run.
  final int timeoutFactor;

  /// The accepted equivalent matching [mutant] of [file] on [sourceLine].
  Equivalent? equivalentFor(String file, Mutant mutant, String sourceLine) {
    for (final e in equivalents) {
      if (e.file == file &&
          e.operator == mutant.operator.name &&
          e.line == sourceLine.trim() &&
          e.replacement == mutant.replacement) {
        return e;
      }
    }
    return null;
  }
}

enum Verdict { killed, survived, timedOut, nonViable }

final _compileError = RegExp(
  r'Failed to load|Compilation failed|\.dart:\d+:\d+: Error:',
);

/// What one `flutter test` run of a mutant says about it.
Verdict verdictOf({
  required int exitCode,
  required String output,
  bool timedOut = false,
}) {
  if (timedOut) return Verdict.timedOut;
  if (exitCode == 0) return Verdict.survived;
  return _compileError.hasMatch(output) ? Verdict.nonViable : Verdict.killed;
}

/// Detected (killed + timed out) over the viable mutants.
class Score {
  Score(Map<Verdict, int> counts) : counts = Map.unmodifiable(counts);

  final Map<Verdict, int> counts;

  int _count(Verdict v) => counts[v] ?? 0;

  int get detected => _count(Verdict.killed) + _count(Verdict.timedOut);
  int get viable => detected + _count(Verdict.survived);

  /// The score in percent, rounded down; 100 without viable mutants.
  int get percent => viable == 0 ? 100 : detected * 100 ~/ viable;

  bool meets(int baseline) => percent >= baseline;
}
