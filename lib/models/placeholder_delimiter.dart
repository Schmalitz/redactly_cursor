import 'package:hive/hive.dart';

part 'placeholder_delimiter.g.dart';

@HiveType(typeId: 3)
enum PlaceholderDelimiter {
  @HiveField(0)
  square,   // [[PLHL1]]
  @HiveField(1)
  curly,    // {{PLHL1}}
  @HiveField(2)
  hash,     // ##PLHL1##
  @HiveField(3)
  round,    // (PLHL1)
  @HiveField(4)
  angle,    // <PLHL1>
}

extension PlaceholderDelimiterX on PlaceholderDelimiter {
  String get open {
    switch (this) {
      case PlaceholderDelimiter.square: return '[[';
      case PlaceholderDelimiter.curly:  return '{{';
      case PlaceholderDelimiter.hash:   return '##';
      case PlaceholderDelimiter.round:  return '(';
      case PlaceholderDelimiter.angle:  return '<';
    }
  }

  String get close {
    switch (this) {
      case PlaceholderDelimiter.square: return ']]';
      case PlaceholderDelimiter.curly:  return '}}';
      case PlaceholderDelimiter.hash:   return '##';
      case PlaceholderDelimiter.round:  return ')';
      case PlaceholderDelimiter.angle:  return '>';
    }
  }

  String wrap(String tokenCore) => '$open$tokenCore$close';
}
