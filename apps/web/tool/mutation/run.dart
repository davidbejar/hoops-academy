// Mutation testing of the web rule code (WP88, docs/quality/mutation.md).
//
//   dart run tool/mutation/run.dart [--manifest tool/mutation/manifest.json]
//       [--workers 3] [--target lib/...dart] [--list]
//
// For every file of the manifest, each mutant (mutation.dart) is written into
// a private copy of apps/web and the file's tests run there with
// `flutter test`; a failing run kills the mutant, a passing one lets it
// survive, a run longer than `timeoutFactor` times the unmutated run times
// out (detected) and a mutant that does not compile is not viable (left out
// of the score). The report goes to build/mutation/report.json and the exit
// code is 1 when the score is below the manifest's baseline.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'mutation.dart';

const _usage =
    'usage: dart run tool/mutation/run.dart [--manifest <json>] '
    '[--workers <n>] [--target <lib file>] [--list]';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final manifest = Manifest.parse(File(options.manifest).readAsStringSync());
  final targets = [
    for (final t in manifest.targets)
      if (options.target == null || options.target == t.file) t,
  ];
  if (targets.isEmpty) _fail('no target ${options.target} in the manifest');

  final plan = [for (final t in targets) _Planned.of(t, manifest)];
  for (final p in plan) {
    stdout.writeln(
      '${p.target.file}: ${p.mutants.length} mutants'
      '${p.equivalents.isEmpty ? '' : ', ${p.equivalents.length} equivalent'}',
    );
    if (options.list) {
      for (final m in p.mutants) {
        stdout.writeln(
          '  ${m.line}:${columnOf(p.source, m)}: ${m.description}',
        );
      }
    }
  }
  if (options.list) return;

  final watch = Stopwatch()..start();
  final workspaces = await _Workspace.create(options.workers);
  try {
    final timeouts = <String, Duration>{};
    for (final p in plan) {
      timeouts[p.target.file] = await workspaces.first.baseline(
        p.target,
        manifest.timeoutFactor,
      );
    }
    final queue = [
      for (final p in plan)
        for (final m in p.mutants) _Job(p, m),
    ];
    final total = queue.length;
    var done = 0;
    await Future.wait([
      for (final w in workspaces)
        () async {
          while (queue.isNotEmpty) {
            final job = queue.removeAt(0);
            job.verdict = await w.run(
              job.planned.target,
              job.mutant,
              timeouts[job.planned.target.file]!,
            );
            done++;
            stdout.writeln(
              '[$done/$total] ${job.verdict!.name.padRight(9)} '
              '${job.planned.target.file}:${job.mutant.line}:'
              '${columnOf(job.planned.source, job.mutant)} '
              '${job.mutant.description}',
            );
            job.planned.results.add(job);
          }
        }(),
    ]);
    watch.stop();
    final exitCode = _report(plan, manifest, watch.elapsed);
    await _cleanUp(workspaces);
    exit(exitCode);
  } catch (e) {
    await _cleanUp(workspaces);
    rethrow;
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  stderr.writeln(_usage);
  exit(2);
}

Future<void> _cleanUp(List<_Workspace> workspaces) async {
  for (final w in workspaces) {
    await w.delete();
  }
}

class _Options {
  _Options({
    required this.manifest,
    required this.workers,
    required this.target,
    required this.list,
  });

  factory _Options.parse(List<String> args) {
    var manifest = 'tool/mutation/manifest.json';
    var workers = 3;
    String? target;
    var list = false;
    for (var i = 0; i < args.length; i++) {
      String value() => i + 1 < args.length ? args[++i] : _fail(args[i]);
      switch (args[i]) {
        case '--manifest':
          manifest = value();
        case '--workers':
          workers = int.tryParse(value()) ?? _fail('--workers takes a number');
        case '--target':
          target = value();
        case '--list':
          list = true;
        default:
          _fail('unknown argument ${args[i]}');
      }
    }
    if (workers < 1) _fail('--workers must be at least 1');
    return _Options(
      manifest: manifest,
      workers: workers,
      target: target,
      list: list,
    );
  }

  final String manifest;
  final int workers;
  final String? target;
  final bool list;
}

/// A target's mutants, the equivalents set aside, and the results.
class _Planned {
  _Planned(this.target, this.source, this.mutants, this.equivalents);

  factory _Planned.of(Target target, Manifest manifest) {
    final source = File(target.file).readAsStringSync();
    final mutants = <Mutant>[];
    final equivalents = <(Mutant, Equivalent)>[];
    for (final m in findMutants(source, only: target.only)) {
      final accepted = manifest.equivalentFor(target.file, m, source);
      if (accepted == null) {
        mutants.add(m);
      } else {
        equivalents.add((m, accepted));
      }
    }
    return _Planned(target, source, mutants, equivalents);
  }

  final Target target;
  final String source;
  final List<Mutant> mutants;
  final List<(Mutant, Equivalent)> equivalents;
  final List<_Job> results = [];
}

class _Job {
  _Job(this.planned, this.mutant);
  final _Planned planned;
  final Mutant mutant;
  Verdict? verdict;
}

/// A private copy of apps/web in which one mutant at a time is tested.
class _Workspace {
  _Workspace(this.dir);

  final Directory dir;

  static Future<List<_Workspace>> create(int count) async {
    final root = Directory.current;
    final base = await Directory.systemTemp.createTemp('hoops-mutation-');
    final workspaces = <_Workspace>[];
    for (var i = 0; i < count; i++) {
      final dir = Directory('${base.path}/w$i')..createSync();
      for (final entity in root.listSync()) {
        final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        if (name == 'build' || name == '.dart_tool') continue;
        await _copy(entity, '${dir.path}/$name');
      }
      final tool = Directory('${dir.path}/.dart_tool')..createSync();
      for (final name in ['package_config.json', 'package_graph.json']) {
        final file = File('${root.path}/.dart_tool/$name');
        if (file.existsSync()) file.copySync('${tool.path}/$name');
      }
      workspaces.add(_Workspace(dir));
    }
    return workspaces;
  }

  static Future<void> _copy(FileSystemEntity entity, String to) async {
    if (entity is File) {
      entity.copySync(to);
    } else if (entity is Directory) {
      Directory(to).createSync(recursive: true);
      for (final child in entity.listSync()) {
        final name = child.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        await _copy(child, '$to/$name');
      }
    }
  }

  /// Runs [target]'s tests unmutated; they must pass. Returns the timeout of
  /// one mutant's run.
  Future<Duration> baseline(Target target, int factor) async {
    final watch = Stopwatch()..start();
    final run = await _flutterTest(target, const Duration(minutes: 10));
    watch.stop();
    if (run.exitCode != 0 || run.timedOut) {
      stderr.writeln(run.output);
      throw StateError('the tests of ${target.file} fail without a mutant');
    }
    final timeout = watch.elapsed * factor;
    const minimum = Duration(seconds: 60);
    return timeout < minimum ? minimum : timeout;
  }

  Future<Verdict> run(Target target, Mutant mutant, Duration timeout) async {
    final file = File('${dir.path}/${target.file}');
    final original = file.readAsStringSync();
    file.writeAsStringSync(applyMutant(original, mutant));
    try {
      final run = await _flutterTest(target, timeout);
      return verdictOf(
        exitCode: run.exitCode,
        output: run.output,
        timedOut: run.timedOut,
      );
    } finally {
      file.writeAsStringSync(original);
    }
  }

  Future<_Run> _flutterTest(Target target, Duration timeout) async {
    final process = await Process.start('flutter', [
      'test',
      '--no-pub',
      '--concurrency=2',
      ...target.tests,
    ], workingDirectory: dir.path);
    final output = StringBuffer();
    final out = process.stdout.transform(utf8.decoder).listen(output.write);
    final err = process.stderr.transform(utf8.decoder).listen(output.write);
    var timedOut = false;
    final exitCode = await process.exitCode.timeout(
      timeout,
      onTimeout: () async {
        timedOut = true;
        process.kill(ProcessSignal.sigterm);
        // flutter_tester children of the killed tool still run in this copy
        await Process.run('pkill', ['-f', dir.path]);
        return process.exitCode.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            process.kill(ProcessSignal.sigkill);
            return -9;
          },
        );
      },
    );
    await out.cancel();
    await err.cancel();
    return _Run(exitCode, output.toString(), timedOut);
  }

  Future<void> delete() async {
    if (dir.parent.existsSync()) {
      await dir.parent.delete(recursive: true);
    }
  }
}

class _Run {
  const _Run(this.exitCode, this.output, this.timedOut);
  final int exitCode;
  final String output;
  final bool timedOut;
}

int _report(List<_Planned> plan, Manifest manifest, Duration elapsed) {
  final counts = <Verdict, int>{};
  final files = <Map<String, Object>>[];
  stdout.writeln('\nMutation testing of the web rule code');
  for (final p in plan) {
    final perFile = <Verdict, int>{};
    for (final job in p.results) {
      perFile.update(job.verdict!, (n) => n + 1, ifAbsent: () => 1);
      counts.update(job.verdict!, (n) => n + 1, ifAbsent: () => 1);
    }
    final score = Score(perFile);
    stdout.writeln(
      '  ${p.target.file}: ${score.detected}/${score.viable} '
      '(${score.percent} %), ${perFile[Verdict.nonViable] ?? 0} not viable, '
      '${p.equivalents.length} equivalent',
    );
    final survivors = [
      for (final job in p.results)
        if (job.verdict == Verdict.survived) job.mutant,
    ]..sort((a, b) => a.offset.compareTo(b.offset));
    for (final m in survivors) {
      stdout.writeln(
        '    SURVIVED ${p.target.file}:${m.line}:${columnOf(p.source, m)} '
        '${m.description}',
      );
    }
    files.add({
      'file': p.target.file,
      'counts': {for (final e in perFile.entries) e.key.name: e.value},
      'survived': [
        for (final m in survivors)
          {
            'line': m.line,
            'column': columnOf(p.source, m),
            'mutant': m.description,
          },
      ],
      'equivalent': [
        for (final (m, e) in p.equivalents)
          {
            'line': m.line,
            'column': columnOf(p.source, m),
            'mutant': m.description,
            'reason': e.reason,
          },
      ],
    });
  }
  final score = Score(counts);
  final passed = score.meets(manifest.baseline);
  stdout.writeln(
    'Total: ${score.detected}/${score.viable} detected (${score.percent} %; '
    'killed ${counts[Verdict.killed] ?? 0}, timed out '
    '${counts[Verdict.timedOut] ?? 0}, survived '
    '${counts[Verdict.survived] ?? 0}), ${counts[Verdict.nonViable] ?? 0} not '
    'viable, baseline ${manifest.baseline} %: '
    '${passed ? 'met' : 'NOT MET'}; ${elapsed.inSeconds} s',
  );
  final report = File('build/mutation/report.json')
    ..createSync(recursive: true);
  report.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'baseline': manifest.baseline,
      'score': score.percent,
      'detected': score.detected,
      'viable': score.viable,
      'counts': {for (final e in counts.entries) e.key.name: e.value},
      'seconds': elapsed.inSeconds,
      'files': files,
    }),
  );
  return passed ? 0 : 1;
}
