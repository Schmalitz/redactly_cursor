import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:anonymizer/screens/editor_screen/highlighting_text_controller.dart';
import 'package:anonymizer/utils/regex_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  RegExp buildSearch(String query, {required bool whole, required bool caseSensitive}) {
    if (query.isEmpty) return RegExp(r'(?!x)x');
    return whole
        ? buildNeedleRegex(needle: query, wholeWord: true, caseSensitive: caseSensitive)
        : RegExp(RegExp.escape(query), caseSensitive: caseSensitive);
  }

  Future<void> findNextAndScrollLikeEditor({
    required WidgetTester tester,
    required HighlightingTextController controller,
    required String text,
    required String query,
    required bool whole,
    required bool caseSensitive,
    required ValueNotifier<int> activeIndex,
  }) async {
    final re = buildSearch(query, whole: whole, caseSensitive: caseSensitive);
    final matches = re.allMatches(text).toList();
    if (matches.isEmpty) {
      activeIndex.value = -1;
      return;
    }
    final next = (activeIndex.value + 1) % matches.length;
    activeIndex.value = next;

    final m = matches[next];

    // Verhalten aus _onFindNext: Caret setzen -> Editor scrollt (in der App).
    controller.selection = TextSelection.collapsed(offset: m.start);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selection = TextSelection.collapsed(offset: m.end);
    });
    await tester.pump(); // postFrameCallback ausführen
  }

  group('Editor search scroll (selection-driven)', () {
    testWidgets(
      'Selection jumps to each next match (collapsed at end) – case-insensitive, partial word',
          (tester) async {
        final repeated = List.filled(50, 'lorem und ipsum\n').join(); // statt "string * 50"
        final controller = HighlightingTextController(
          mappings: const [],
          isCaseSensitiveForSearch: false,
          isWholeWordForSearch: false,
          searchQuery: '',
          activeSearchMatchIndex: -1,
          text: 'und X\n$repeated' 'finale und ende',
        );

        final text = controller.text;
        final query = 'und';
        final whole = false;
        final cs = false;
        final re = buildSearch(query, whole: whole, caseSensitive: cs);
        final ms = re.allMatches(text).toList();
        expect(ms.length, greaterThan(2)); // jetzt korrekt > 2

        final activeIndex = ValueNotifier<int>(-1);

        // 1. Treffer
        await findNextAndScrollLikeEditor(
          tester: tester,
          controller: controller,
          text: text,
          query: query,
          whole: whole,
          caseSensitive: cs,
          activeIndex: activeIndex,
        );
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, equals(controller.selection.extentOffset));
        expect(controller.selection.baseOffset, equals(ms[0].end));

        // 2. Treffer
        await findNextAndScrollLikeEditor(
          tester: tester,
          controller: controller,
          text: text,
          query: query,
          whole: whole,
          caseSensitive: cs,
          activeIndex: activeIndex,
        );
        expect(controller.selection.baseOffset, equals(ms[1].end));

        // 3. Treffer (Stichprobe)
        await findNextAndScrollLikeEditor(
          tester: tester,
          controller: controller,
          text: text,
          query: query,
          whole: whole,
          caseSensitive: cs,
          activeIndex: activeIndex,
        );
        expect(controller.selection.baseOffset, equals(ms[2].end));
      },
    );

    testWidgets(
      'Whole-word + case-sensitive works and moves to the right offsets',
          (tester) async {
        final controller = HighlightingTextController(
          mappings: const [],
          isCaseSensitiveForSearch: true,
          isWholeWordForSearch: true,
          searchQuery: '',
          activeSearchMatchIndex: -1,
          text: 'Und und UND\nund-lich\n und \nund.\nUND!',
        );

        final text = controller.text;
        final query = 'und';
        final whole = true;
        final cs = true;

        // Hinweis: Euer wholeWord-Regex behandelt '-' als Wortgrenze.
        // Matches (klein, exakt, Whole Word): "und" in "Und und UND" (das mittlere),
        // "und-" in "und-lich", " und " sowie "und."  => 4 Matches total.
        final re = buildSearch(query, whole: whole, caseSensitive: cs);
        final ms = re.allMatches(text).toList();
        expect(ms.length, equals(4));

        final activeIndex = ValueNotifier<int>(-1);

        // 1. Match
        await findNextAndScrollLikeEditor(
          tester: tester,
          controller: controller,
          text: text,
          query: query,
          whole: whole,
          caseSensitive: cs,
          activeIndex: activeIndex,
        );
        expect(controller.selection.baseOffset, equals(ms[0].end));

        // 2. Match
        await findNextAndScrollLikeEditor(
          tester: tester,
          controller: controller,
          text: text,
          query: query,
          whole: whole,
          caseSensitive: cs,
          activeIndex: activeIndex,
        );
        expect(controller.selection.baseOffset, equals(ms[1].end));

        // 3. Match
        await findNextAndScrollLikeEditor(
          tester: tester,
          controller: controller,
          text: text,
          query: query,
          whole: whole,
          caseSensitive: cs,
          activeIndex: activeIndex,
        );
        expect(controller.selection.baseOffset, equals(ms[2].end));

        // 4. Match
        await findNextAndScrollLikeEditor(
          tester: tester,
          controller: controller,
          text: text,
          query: query,
          whole: whole,
          caseSensitive: cs,
          activeIndex: activeIndex,
        );
        expect(controller.selection.baseOffset, equals(ms[3].end));

        // Wrap-around zurück zum ersten
        await findNextAndScrollLikeEditor(
          tester: tester,
          controller: controller,
          text: text,
          query: query,
          whole: whole,
          caseSensitive: cs,
          activeIndex: activeIndex,
        );
        expect(controller.selection.baseOffset, equals(ms[0].end));
      },
    );
  });
}
