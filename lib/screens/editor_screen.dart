import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redactly/models/placeholder_mapping.dart';

import '../providers/placeholder_mapping_provider.dart';
import '../providers/text_state_provider.dart';
import '../providers/mode_provider.dart';
import '../widgets/mapping_list_widget.dart';
import '../widgets/preview_text_widget.dart';

/// Dies ist ein spezieller, benutzerdefinierter TextEditingController.
/// Er kann seinen Text basierend auf einer Liste von Mappings farbig darstellen.
class HighlightingTextController extends TextEditingController {
  /// Die Liste der Wörter, die farbig markiert werden sollen.
  /// Diese ist jetzt nicht mehr 'final', damit wir sie aktualisieren können.
  List<PlaceholderMapping> mappings;

  HighlightingTextController({required this.mappings, String? text})
      : super(text: text);

  /// Diese Methode wird vom TextField aufgerufen, um den Text zu zeichnen.
  /// Hier definieren wir unsere Logik für die farbigen Markierungen.
  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
        TextStyle? style,
        required bool withComposing}) {
    final List<InlineSpan> children = [];
    final text = this.text;

    if (mappings.isEmpty || text.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    // Sortieren, damit längere Begriffe zuerst gefunden werden (z.B. "Max Mustermann" vor "Max")
    final sortedMappings = [...mappings]
      ..sort((a, b) => b.originalText.length.compareTo(a.originalText.length));

    int lastMatchEnd = 0;

    final regexParts = sortedMappings
        .map((m) => RegExp.escape(m.originalText))
        .where((p) => p.isNotEmpty);

    if (regexParts.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final regex = RegExp(regexParts.join('|'), caseSensitive: true);
    final matches = regex.allMatches(text);

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final mapping =
      sortedMappings.firstWhere((m) => m.originalText == match.group(0)!);
      children.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          backgroundColor: mapping.color.withOpacity(0.4),
        ),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      children.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return TextSpan(style: style, children: children);
  }
}

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final HighlightingTextController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HighlightingTextController(
      mappings: ref.read(placeholderMappingProvider),
      text: ref.read(textInputProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mappings = ref.watch(placeholderMappingProvider);

    // **HIER IST DIE KORREKTUR:**
    // Wir aktualisieren die Mapping-Liste des Controllers bei jeder Änderung.
    // Da das Feld `mappings` im Controller nicht mehr 'final' ist, funktioniert das jetzt.
    _controller.mappings = mappings;

    final text = ref.watch(textInputProvider);
    final mode = ref.watch(redactModeProvider);

    ref.listen<String>(textInputProvider, (previous, next) {
      if (_controller.text != next) {
        final selection = _controller.selection;
        _controller.text = next;
        if (selection.start <= next.length && selection.end <= next.length) {
          _controller.selection = selection;
        }
      }
    });

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final previewColor = Colors.grey.shade200;
    final inputColor = Colors.white;
    final borderColor = Colors.grey.shade400;

    const contentPadding = EdgeInsets.all(12.0);
    final inputDecoration = BoxDecoration(
      color: inputColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(12),
    );
    final previewDecoration = BoxDecoration(
      color: previewColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode == RedactMode.anonymize
                              ? "Original Text"
                              : "Anonymized Text",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: inputDecoration,
                            padding: contentPadding,
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                // *** HIER IST DIE LÖSUNG ***
                                // Wir geben dem Editor ein eigenes Mini-Theme,
                                // nur um die Markierungsfarbe zu definieren.
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    textSelectionTheme: const TextSelectionThemeData(
                                      // Ändern Sie diese Farbe nach Belieben.
                                      // `Colors.amber` ist ein kräftiges, sattes Gelb.
                                      selectionColor: Colors.amber,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _controller,
                                    maxLines: null,
                                    onChanged: (value) => ref
                                        .read(textInputProvider.notifier)
                                        .state = value,
                                    decoration: InputDecoration(
                                      hintText: mode == RedactMode.anonymize
                                          ? 'Paste your original text to be anonymized here'
                                          : 'Paste your anonymized text here',
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(
                                        fontSize: 16, height: 1.5),
                                    keyboardType: TextInputType.multiline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 16, top: 16),
                        child: Text("Placeholders",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: MappingListWidget(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode == RedactMode.anonymize ? "Preview" : "Result",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: previewDecoration,
                            padding: contentPadding,
                            child: const Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                primary: true,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: PreviewTextWidget(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (mode == RedactMode.anonymize)
                      ElevatedButton(
                        onPressed: () {
                          final selection = _controller.selection;
                          if (!selection.isCollapsed) {
                            final selectedText = _controller.text
                                .substring(selection.start, selection.end);
                            if (selectedText.trim().isNotEmpty) {
                              ref
                                  .read(placeholderMappingProvider.notifier)
                                  .addMapping(selectedText.trim());
                            }
                          }
                        },
                        child: const Text('Set Placeholder'),
                      )
                    else
                      const SizedBox(width: 140),
                    ElevatedButton(
                      onPressed: () {
                        final raw = ref.read(textInputProvider);
                        final mappings = ref.read(placeholderMappingProvider);
                        final currentMode = ref.read(redactModeProvider);
                        String result = raw;
                        for (final m in mappings) {
                          result = currentMode == RedactMode.anonymize
                              ? result.replaceAll(m.originalText, m.placeholder)
                              : result.replaceAll(m.placeholder, m.originalText);
                        }
                        Clipboard.setData(ClipboardData(text: result));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Copied to clipboard')),
                        );
                      },
                      child: const Text('Copy Preview'),
                    ),
                  ],
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: mode == RedactMode.anonymize
                        ? Colors.purple.shade400
                        : Colors.deepPurple.shade400,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 18),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99)),
                  ),
                  onPressed: () {
                    final newMode = mode == RedactMode.anonymize
                        ? RedactMode.deanonymize
                        : RedactMode.anonymize;
                    ref.read(redactModeProvider.notifier).state = newMode;
                    if (newMode == RedactMode.deanonymize) {
                      _controller.clear();
                      ref.read(textInputProvider.notifier).state = '';
                    }
                  },
                  child: const Text('Redactly',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}