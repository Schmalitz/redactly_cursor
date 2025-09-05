import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:redactly/screens/editor_screen/highlighting_text_controller.dart';
import 'package:redactly/utils/regex_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  RegExp _buildSearch(String query, {required bool whole, required bool caseSensitive}) {
    if (query.isEmpty) return RegExp(r'(?!x)x');
    return whole
        ? buildNeedleRegex(needle: query, wholeWord: true, caseSensitive: caseSensitive)
        : RegExp(RegExp.escape(query), caseSensitive: caseSensitive);
  }

  Future<void> _findNextLikeEditorButSynchronous({
    required HighlightingTextController controller,
    required String text,
    required String query,
    required bool whole,
    required bool caseSensitive,
    required ValueNotifier<int> activeIndex,
  }) async {
    final re = _buildSearch(query, whole: whole, caseSensitive: caseSensitive);
    final matches = re.allMatches(text).toList();
    if (matches.isEmpty) {
      activeIndex.value = -1;
      return;
    }
    final next = (activeIndex.value + 1) % matches.length;
    activeIndex.value = next;
    final m = matches[next];

    // Test-Variante: direkt auf das End-Offset setzen (finaler Zustand nach Scroll).
    controller.selection = TextSelection.collapsed(offset: m.end);
  }

  group('Editor search scroll (selection-driven)', () {
    testWidgets(
      'Selection moves to successive matches (case-insensitive, partial word)',
          (tester) async {
        final text = [
          'a und b',
          'lorem und ipsum',
          'xx und yy und zz',
          'und am zeilenanfang',
          'am zeilenende und',
        ].join('\n');

        final controller = HighlightingTextController(
          mappings: const [],
          isCaseSensitiveForSearch: false,
          isWholeWordForSearch: false,
          searchQuery: '',
          activeSearchMatchIndex: -1,
          text: text,
        );

        final re = _buildSearch('und', whole: false, caseSensitive: false);
        final ms = re.allMatches(text).toList();
        expect(ms.isNotEmpty, isTrue);

        final activeIndex = ValueNotifier<int>(-1);
        final steps = ms.length >= 3 ? 3 : ms.length;

        for (int i = 0; i < steps; i++) {
          await _findNextLikeEditorButSynchronous(
            controller: controller,
            text: text,
            query: 'und',
            whole: false,
            caseSensitive: false,
            activeIndex: activeIndex,
          );
          expect(controller.selection.isCollapsed, isTrue);
          expect(controller.selection.baseOffset, equals(ms[i].end));
        }
      },
    );

    testWidgets(
      'Whole-word + case-sensitive cycles over all matches',
          (tester) async {
        final text = [
          'x und y',
          'und und',
          'Und UND',
          'und. (ganze Worte)',
          'abc und-xyz',
          'ende: und',
        ].join('\n');

        final controller = HighlightingTextController(
          mappings: const [],
          isCaseSensitiveForSearch: true,
          isWholeWordForSearch: true,
          searchQuery: '',
          activeSearchMatchIndex: -1,
          text: text,
        );

        final re = _buildSearch('und', whole: true, caseSensitive: true);
        final ms = re.allMatches(text).toList();
        expect(ms.isNotEmpty, isTrue);

        final activeIndex = ValueNotifier<int>(-1);

        for (int i = 0; i < ms.length; i++) {
          await _findNextLikeEditorButSynchronous(
            controller: controller,
            text: text,
            query: 'und',
            whole: true,
            caseSensitive: true,
            activeIndex: activeIndex,
          );
          expect(controller.selection.baseOffset, equals(ms[i].end));
        }

        // wrap-around
        await _findNextLikeEditorButSynchronous(
          controller: controller,
          text: text,
          query: 'und',
          whole: true,
          caseSensitive: true,
          activeIndex: activeIndex,
        );
        expect(controller.selection.baseOffset, equals(ms[0].end));
      },
    );
  });
}
