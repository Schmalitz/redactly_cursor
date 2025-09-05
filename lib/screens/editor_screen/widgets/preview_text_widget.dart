import 'dart:async';

import 'package:redactly/models/placeholder_mapping.dart';
import 'package:redactly/providers/mode_provider.dart';
import 'package:redactly/providers/placeholder_mapping_provider.dart';
import 'package:redactly/providers/text_state_provider.dart';
import 'package:redactly/services/mapping_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreviewTextWidget extends ConsumerStatefulWidget {
  const PreviewTextWidget({super.key});
  @override
  ConsumerState<PreviewTextWidget> createState() => _PreviewTextWidgetState();
}

class _PreviewTextWidgetState extends ConsumerState<PreviewTextWidget> {
  String _rendered = '';
  Timer? _debounce;
  int _jobToken = 0; // simple cancellation token

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleCompute(String input, List<PlaceholderMapping> mappings, RedactMode mode) {
    _debounce?.cancel();
    final myToken = ++_jobToken;

    _debounce = Timer(const Duration(milliseconds: 120), () async {
      final out = await applyMappingsIsolate(text: input, mappings: mappings, mode: mode);
      if (!mounted || myToken != _jobToken) return; // drop stale result
      setState(() => _rendered = out);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode      = ref.watch(redactModeProvider);
    final input     = ref.watch(mode == RedactMode.anonymize ? anonymizeInputProvider : deanonymizeInputProvider);
    final mappings  = ref.watch(placeholderMappingProvider);

    // Bei jeder Änderung neu planen
    _scheduleCompute(input, mappings, mode);

    if (mode == RedactMode.deanonymize) {
      return SelectableText(
        _rendered,
        style: const TextStyle(fontSize: 16, height: 1.5),
        textAlign: TextAlign.start,
      );
    }

    // Anonymize: Placeholder farbig hervorheben
    final spans = _buildSpans(_rendered, mappings);
    return SelectableText.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 16, height: 1.5),
      textAlign: TextAlign.start,
      textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false),
    );
  }

  List<InlineSpan> _buildSpans(String text, List<PlaceholderMapping> mappings) {
    final spans = <InlineSpan>[];
    if (text.isEmpty) return spans;
    final sorted = [...mappings]..sort((a, b) => b.placeholder.length.compareTo(a.placeholder.length));

    int i = 0;
    while (i < text.length) {
      bool matched = false;
      for (final m in sorted) {
        if (m.placeholder.isEmpty) continue;
        if (text.startsWith(m.placeholder, i)) {
          spans.add(TextSpan(
            text: m.placeholder,
            style: TextStyle(
              backgroundColor: m.color.withOpacity(0.3),
              fontWeight: FontWeight.w600,
            ),
          ));
          i += m.placeholder.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        spans.add(TextSpan(text: text[i]));
        i++;
      }
    }
    return spans;
  }
}
