// The scale benchmark: what a page with thousands of nodes costs to plan and to write.
//
// Run by `tool/scale.sh`, which compares the report with `tool/scale_baseline.json`; see
// `PLAN_PERFORMANCE.md` for why these three shapes, and what each one is looking for.
//
// Usage, from the repository root:
//
//     tool/scale.sh                 measure, then compare with the baseline
//     tool/scale.sh --update        measure, and accept it as the new baseline
//     (cd packages/unibox_html && dart run tool/bench.dart --json)
//
// It lives in this package rather than in `tool/` because a script outside a package
// cannot import one: `unibox_html` already depends on `unibox_core`, `unibox_css` and
// `unibox_element`, which is the whole of the pipeline being timed.
import 'dart:convert';
import 'dart:io';

import 'package:unibox_core/unibox_core.dart' as core;
import 'package:unibox_element/unibox_element.dart';
import 'package:unibox_html/unibox_html.dart';

/// How many passes a stage is timed over, whose median is reported.
///
/// A median rather than a mean, because one allocation pause should not become the number
/// a baseline is written from.
const int _repeats = 5;

/// The name of a shape, and the two sizes it is measured at.
final class _Shape {
  const _Shape(this.name, this.build, this.small, this.large);

  /// The name the report and the baseline use.
  final String name;

  /// The tree at a given size: rows for the row shapes, depth for the chain.
  final core.UINode Function(int size) build;

  /// The smaller size, and the larger one, which is twice it.
  final int small;
  final int large;
}

/// The three shapes, in the order the table prints them.
///
/// They are the three ways a page grows: many siblings dressed alike, many siblings
/// dressed differently, and depth. A pipeline that is linear in one and quadratic in
/// another has a bug in it, and only measuring all three says which.
final List<_Shape> _shapes = <_Shape>[
  _Shape('shared-look', _rows(shared: true), 1500, 3000),
  _Shape('distinct-look', _rows(shared: false), 1500, 3000),
  _Shape('deep-chain', _chain, 800, 1600),
];

/// [rows] rows of three labels each, dressed alike or one colour per row.
///
/// A shared look is what a page written by hand looks like; a distinct one is what a list
/// drawn from a store looks like when the styling follows the data. The second is the
/// shape a class registry that scans its own rules cannot keep linear.
core.UINode Function(int) _rows({required bool shared}) =>
    (int rows) => core.Box(
      direction: core.Axis.vertical,
      children: <core.UINode>[
        for (int i = 0; i < rows; i++)
          core.Box(
            direction: core.Axis.horizontal,
            padding: const core.BoxSpacing.all(8),
            gap: 12,
            backgroundColor: shared
                ? null
                : core.BoxColor(0xFF000000 | (i & 0xFFFFFF)),
            children: <core.UINode>[
              core.TextNode('Row $i'),
              const core.TextNode('A description'),
              const core.TextNode(
                'Action',
                style: core.BoxTextStyle(fontWeight: core.FontWeight.semiBold),
              ),
            ],
          ),
      ],
    );

/// [depth] boxes nested one inside the next, with a label at the bottom.
///
/// Depth is the shape that punishes an emitter which returns a string per element and
/// lets its parent copy it: the label travels through every level above it.
core.UINode _chain(int depth) {
  core.UINode node = const core.TextNode('bottom');

  for (int i = 0; i < depth; i++) {
    node = core.Box(children: <core.UINode>[node]);
  }

  return node;
}

/// How many nodes [tree] holds, which is what "size" means in the report.
int _count(core.UINode node) =>
    1 +
    node.children.fold(0, (int sum, core.UINode child) => sum + _count(child));

/// The median of [samples], in milliseconds.
double _median(List<double> samples) {
  final List<double> sorted = samples.toList()..sort();

  return sorted[sorted.length ~/ 2];
}

/// One tree, measured: the exact facts about what it produced, and the times.
///
/// The first pass is discarded, so the numbers do not include the JIT compiling the
/// renderer: what is measured is a warm pipeline, which is what a server and a browser
/// both run.
Map<String, Object> _measure(core.UINode tree) {
  final List<double> plans = <double>[];
  final List<double> writes = <double>[];
  final List<double> sheets = <double>[];
  int classes = 0;
  int htmlBytes = 0;
  int cssBytes = 0;

  for (int pass = 0; pass <= _repeats; pass++) {
    final Stylesheet sheet = Stylesheet();

    final Stopwatch clock = Stopwatch()..start();
    final ElementPlan plan = planNode(tree, sheet);
    final double planMs = clock.elapsedMicroseconds / 1000;

    clock.reset();
    final String css = documentCss(sheet);
    final double cssMs = clock.elapsedMicroseconds / 1000;

    clock.reset();
    final String html = writeElement(plan);
    final double writeMs = clock.elapsedMicroseconds / 1000;

    classes = sheet.length;
    htmlBytes = html.length;
    cssBytes = css.length;

    if (pass > 0) {
      plans.add(planMs);
      sheets.add(cssMs);
      writes.add(writeMs);
    }
  }

  return <String, Object>{
    'nodes': _count(tree),
    'classes': classes,
    'html_bytes': htmlBytes,
    'css_bytes': cssBytes,
    'plan_ms': _median(plans),
    'css_ms': _median(sheets),
    'write_ms': _median(writes),
  };
}

/// Every measurement, as the report the guard reads.
Map<String, Object> _report() {
  final Map<String, Object> shapes = <String, Object>{};

  for (final _Shape shape in _shapes) {
    shapes[shape.name] = <String, Object>{
      'small': _measure(shape.build(shape.small)),
      'large': _measure(shape.build(shape.large)),
    };
  }

  return <String, Object>{'repeats': _repeats, 'shapes': shapes};
}

/// A table a human reads before accepting a baseline.
void _printTable(Map<String, Object> report) {
  final List<String> lines = <String>[
    '${'shape'.padRight(14)}${'size'.padLeft(7)}'
        '${'nodes'.padLeft(8)}${'classes'.padLeft(9)}'
        '${'plan'.padLeft(10)}${'css'.padLeft(10)}${'write'.padLeft(11)}'
        '${'html'.padLeft(11)}${'css'.padLeft(11)}',
  ];

  final Map<String, Object> shapes = report['shapes']! as Map<String, Object>;

  for (final MapEntry<String, Object> shape in shapes.entries) {
    final Map<String, Object> sizes = shape.value as Map<String, Object>;

    for (final MapEntry<String, Object> size in sizes.entries) {
      final Map<String, Object> row = size.value as Map<String, Object>;

      lines.add(
        '${shape.key.padRight(14)}${size.key.padLeft(7)}'
        '${row['nodes'].toString().padLeft(8)}'
        '${row['classes'].toString().padLeft(9)}'
        '${_milliseconds(row['plan_ms']).padLeft(10)}'
        '${_milliseconds(row['css_ms']).padLeft(10)}'
        '${_milliseconds(row['write_ms']).padLeft(11)}'
        '${row['html_bytes'].toString().padLeft(11)}'
        '${row['css_bytes'].toString().padLeft(11)}',
      );
    }
  }

  stdout.writeln(lines.join('\n'));
}

/// [value] as a column of milliseconds.
String _milliseconds(Object? value) =>
    '${(value! as double).toStringAsFixed(1)}ms';

void main(List<String> arguments) {
  final Map<String, Object> report = _report();

  if (arguments.contains('--json')) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));

    return;
  }

  _printTable(report);
}
