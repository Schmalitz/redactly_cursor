import 'package:hive/hive.dart';
import 'placeholder_delimiter.dart';

part 'session_props.g.dart';

@HiveType(typeId: 5)
class SessionProps {
  @HiveField(0)
  final bool isCaseSensitive;

  @HiveField(1)
  final bool isWholeWord;

  @HiveField(2)
  final PlaceholderDelimiter delimiter;

  /// Laufende Nummer für die nächste Platzhalter-Vergabe (z. B. PLHL1, PLHL2 …).
  @HiveField(3)
  final int nextPlaceholderIndex;

  const SessionProps({
    this.isCaseSensitive = true,
    this.isWholeWord = true,
    this.delimiter = PlaceholderDelimiter.square,
    this.nextPlaceholderIndex = 1,
  });

  SessionProps copyWith({
    bool? isCaseSensitive,
    bool? isWholeWord,
    PlaceholderDelimiter? delimiter,
    int? nextPlaceholderIndex,
  }) {
    return SessionProps(
      isCaseSensitive: isCaseSensitive ?? this.isCaseSensitive,
      isWholeWord: isWholeWord ?? this.isWholeWord,
      delimiter: delimiter ?? this.delimiter,
      nextPlaceholderIndex: nextPlaceholderIndex ?? this.nextPlaceholderIndex,
    );
  }
}
