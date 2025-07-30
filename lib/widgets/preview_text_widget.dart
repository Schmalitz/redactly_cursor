import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/providers/settings_provider.dart';
import '../providers/text_state_provider.dart';
import '../providers/placeholder_mapping_provider.dart';
import '../providers/mode_provider.dart';
import '../models/placeholder_mapping.dart';

class PreviewTextWidget extends ConsumerWidget {
  const PreviewTextWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final originalText = ref.watch(textInputProvider);
    final mappings = ref.watch(placeholderMappingProvider);
    final mode = ref.watch(redactModeProvider);
    final isCaseSensitive = ref.watch(caseSensitiveProvider);
    final isWholeWord = ref.watch(wholeWordProvider);

    final replacedText = _applyMappings(originalText, mappings, mode,
        isCaseSensitive: isCaseSensitive, isWholeWord: isWholeWord);

    if (mode == RedactMode.deanonymize) {
      return SelectableText(
        replacedText,
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.start,
      );
    }

    final spans = _buildSpans(replacedText, mappings);
    return SelectableText.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 16),
      textAlign: TextAlign.start,
      textHeightBehavior:
      const TextHeightBehavior(applyHeightToFirstAscent: false),
    );
  }

  String _applyMappings(String text, List<PlaceholderMapping> mappings, RedactMode mode,
      {required bool isCaseSensitive, required bool isWholeWord}) {
    var result = text;
    for (final m in mappings) {
      if (mode == RedactMode.anonymize) {
        final pattern = isWholeWord
            ? '\\b${RegExp.escape(m.originalText)}\\b'
            : RegExp.escape(m.originalText);
        result = result.replaceAll(
            RegExp(pattern, caseSensitive: isCaseSensitive), m.placeholder);
      } else {
        result = result.replaceAll(m.placeholder, m.originalText);
      }
    }
    return result;
  }

  List<InlineSpan> _buildSpans(String text, List<PlaceholderMapping> mappings) {
    final spans = <InlineSpan>[];
    if (text.isEmpty) return spans;

    final sorted = [...mappings]
      ..sort((a, b) => b.placeholder.length.compareTo(a.placeholder.length));

    int index = 0;
    while (index < text.length) {
      bool matched = false;
      for (final m in sorted) {
        if (text.startsWith(m.placeholder, index)) {
          spans.add(
            TextSpan(
              text: m.placeholder,
              style: TextStyle(
                backgroundColor: m.color.withOpacity(0.3),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
          index += m.placeholder.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        spans.add(TextSpan(text: text[index]));
        index++;
      }
    }

    return spans;
  }
}