import 'dart:isolate';
import 'package:redactly/models/placeholder_mapping.dart';
import 'package:redactly/providers/mode_provider.dart';
import 'package:redactly/utils/regex_utils.dart';

/// Serialisierbares DTO für Isolate
class _MappingJob {
  final String text;
  final List<_MapItem> maps;
  final bool
      anonymize; // true=Anonymize (original->placeholder), false=De-Anonymize

  _MappingJob(this.text, this.maps, this.anonymize);
}

class _MapItem {
  final String original;
  final String placeholder;
  final bool caseSensitive;
  final bool wholeWord;
  _MapItem(this.original, this.placeholder, this.caseSensitive, this.wholeWord);
}

Future<String> applyMappingsIsolate({
  required String text,
  required List<PlaceholderMapping> mappings,
  required RedactMode mode,
}) async {
  final job = _MappingJob(
    text,
    mappings
        .map((m) => _MapItem(
            m.originalText, m.placeholder, m.isCaseSensitive, m.isWholeWord))
        .toList(),
    mode == RedactMode.anonymize,
  );

  return await Isolate.run(() => _run(job));
}

String _run(_MappingJob job) {
  var result = job.text;
  if (result.isEmpty || job.maps.isEmpty) return result;

  if (job.anonymize) {
    // Längste Originale zuerst
    final sorted = [...job.maps]
      ..sort((a, b) => b.original.length.compareTo(a.original.length));
    for (final m in sorted) {
      if (m.original.isEmpty) continue;
      final regex = m.wholeWord
          ? buildNeedleRegex(
              needle: m.original,
              wholeWord: true,
              caseSensitive: m.caseSensitive,
            )
          : RegExp(RegExp.escape(m.original), caseSensitive: m.caseSensitive);
      result = result.replaceAll(regex, m.placeholder);
    }
  } else {
    // Längste Placeholder zuerst (exakter Match)
    final sorted = [...job.maps]
      ..sort((a, b) => b.placeholder.length.compareTo(a.placeholder.length));
    for (final m in sorted) {
      if (m.placeholder.isEmpty) continue;
      result =
          result.replaceAll(RegExp(RegExp.escape(m.placeholder)), m.original);
    }
  }
  return result;
}
