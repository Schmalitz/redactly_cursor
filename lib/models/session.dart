import 'package:anonymizer/models/session_title_mode.dart';
import 'package:hive/hive.dart';
import 'package:anonymizer/models/placeholder_mapping.dart';

part 'session.g.dart';

@HiveType(typeId: 0)
class Session extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  List<PlaceholderMapping> mappings;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  SessionTitleMode titleMode; // NEU

  Session({
    required this.id,
    required this.title,
    required this.content,
    required this.mappings,
    required this.createdAt,
    this.titleMode = SessionTitleMode.auto, // Standard: automatisch
  });
}
