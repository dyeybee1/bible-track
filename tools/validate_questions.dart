#!/usr/bin/env dart
// tools/validate_questions.dart
//
// Usage:
//   dart tools/validate_questions.dart <bookId> <totalChapters>
//   dart tools/validate_questions.dart mrk 16
//
// Exits with code 0 when the file is valid, 1 with a printed error list otherwise.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('Usage: dart tools/validate_questions.dart <bookId> <totalChapters>');
    exit(2);
  }

  final bookId = args[0];
  final totalChapters = int.tryParse(args[1]);
  if (totalChapters == null || totalChapters < 1) {
    stderr.writeln('Error: totalChapters must be a positive integer.');
    exit(2);
  }

  final path = 'assets/questions/$bookId.json';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Error: file not found: $path');
    exit(1);
  }

  final errors = <String>[];

  late Map<String, dynamic> root;
  try {
    root = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('Error: invalid JSON — $e');
    exit(1);
  }

  if (!root.containsKey('chapters')) {
    errors.add('Missing top-level "chapters" key.');
    _report(errors);
    return;
  }

  final chapters = root['chapters'] as Map<String, dynamic>;

  // Check all chapters 1..N are present
  for (var ch = 1; ch <= totalChapters; ch++) {
    if (!chapters.containsKey('$ch')) {
      errors.add('Chapter $ch is missing.');
    }
  }

  // Check no extra chapters
  for (final key in chapters.keys) {
    final n = int.tryParse(key);
    if (n == null || n < 1 || n > totalChapters) {
      errors.add('Unexpected chapter key: "$key" (valid range 1..$totalChapters).');
    }
  }

  // Validate each chapter's questions
  for (var ch = 1; ch <= totalChapters; ch++) {
    final raw = chapters['$ch'];
    if (raw == null) continue; // already reported as missing

    if (raw is! List) {
      errors.add('Chapter $ch: value is not a list.');
      continue;
    }

    final qs = raw as List<dynamic>;
    if (qs.length < 3 || qs.length > 5) {
      errors.add('Chapter $ch: has ${qs.length} question(s); expected 3–5.');
    }

    for (var qi = 0; qi < qs.length; qi++) {
      final label = 'Chapter $ch Q${qi + 1}';
      final q = qs[qi];
      if (q is! Map) {
        errors.add('$label: not an object.');
        continue;
      }

      // q.en / q.fil
      final qMap = q['q'];
      if (qMap == null) {
        errors.add('$label: missing "q".');
      } else {
        _checkStr(qMap, 'en', label, '"q.en"', errors);
        _checkStr(qMap, 'fil', label, '"q.fil"', errors);
      }

      // options.en / options.fil
      final opts = q['options'];
      if (opts == null) {
        errors.add('$label: missing "options".');
      } else {
        final en = opts['en'];
        final fil = opts['fil'];
        if (en is! List || en.isEmpty) {
          errors.add('$label: "options.en" must be a non-empty list.');
        } else {
          for (var i = 0; i < (en as List).length; i++) {
            if (en[i] is! String || (en[i] as String).trim().isEmpty) {
              errors.add('$label: "options.en[$i]" is empty or not a string.');
            }
          }
        }
        if (fil is! List || fil.isEmpty) {
          errors.add('$label: "options.fil" must be a non-empty list.');
        } else {
          for (var i = 0; i < (fil as List).length; i++) {
            if (fil[i] is! String || (fil[i] as String).trim().isEmpty) {
              errors.add('$label: "options.fil[$i]" is empty or not a string.');
            }
          }
          // same length
          if (opts['en'] is List &&
              (opts['en'] as List).length != (fil).length) {
            errors.add('$label: "options.en" and "options.fil" have different lengths.');
          }
        }

        // answer in range
        final answer = q['answer'];
        if (answer is! int) {
          errors.add('$label: "answer" must be an integer.');
        } else if (opts['en'] is List) {
          final maxIdx = (opts['en'] as List).length - 1;
          if (answer < 0 || answer > maxIdx) {
            errors.add('$label: "answer" ($answer) out of range 0..$maxIdx.');
          }
        }
      }

      // explanation.en / explanation.fil
      final exp = q['explanation'];
      if (exp == null) {
        errors.add('$label: missing "explanation".');
      } else {
        _checkStr(exp, 'en', label, '"explanation.en"', errors);
        _checkStr(exp, 'fil', label, '"explanation.fil"', errors);
      }
    }
  }

  _report(errors);
}

void _checkStr(dynamic map, String key, String label, String field, List<String> errors) {
  if (map is! Map) {
    errors.add('$label: $field parent is not an object.');
    return;
  }
  final v = map[key];
  if (v == null) {
    errors.add('$label: $field is missing.');
  } else if (v is! String) {
    errors.add('$label: $field must be a string.');
  } else if ((v).trim().isEmpty) {
    errors.add('$label: $field is empty.');
  }
}

void _report(List<String> errors) {
  if (errors.isEmpty) {
    stdout.writeln('✅  Valid — no errors found.');
    exit(0);
  } else {
    stderr.writeln('❌  ${errors.length} error(s) found:');
    for (final e in errors) {
      stderr.writeln('  • $e');
    }
    exit(1);
  }
}
