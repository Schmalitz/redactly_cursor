import 'package:flutter_riverpod/flutter_riverpod.dart';

final caseSensitiveProvider = StateProvider<bool>((ref) => true);

final wholeWordProvider = StateProvider<bool>((ref) => true);

final searchPanelVisibleProvider = StateProvider<bool>((ref) => false);

final searchQueryProvider = StateProvider<String>((ref) => '');

final replaceQueryProvider = StateProvider<String>((ref) => '');

final activeSearchMatchIndexProvider = StateProvider<int>((ref) => -1);

final sidebarPinnedProvider = StateProvider<bool>((ref) => false);