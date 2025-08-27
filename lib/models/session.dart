import 'package:anonymizer/models/placeholder_mapping.dart';
import 'package:anonymizer/models/session_props.dart';
import 'package:anonymizer/models/session_title_mode.dart';
import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 0)
class Session extends HiveObject {
  // --- Identität & Titel ---
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(5)
  SessionTitleMode titleMode;

  // --- Zeiten & Status ---
  @HiveField(4)
  final DateTime createdAt;

  @HiveField(10)
  DateTime lastOpenedAt;

  @HiveField(11)
  DateTime updatedAt;

  @HiveField(12)
  bool archived;

  @HiveField(13)
  int schemaVersion;

  // --- Inhalte ---
  /// Input im Anonymize-Modus
  @HiveField(2)
  String originalInput;

  /// Input im De-Anonymize-Modus
  @HiveField(6)
  String placeholderedInput;

  /// Optional: Caches (werden nicht zwingend benötigt)
  @HiveField(14)
  String? placeholderedOutputCache;

  @HiveField(15)
  String? editedOutputCache;

  /// Platzhalter-Definitionen
  @HiveField(3)
  List<PlaceholderMapping> mappings;

  /// Session-spezifische Properties (Delimiter etc.)
  @HiveField(7)
  SessionProps props;

  Session({
    required this.id,
    required this.title,
    required this.originalInput,
    required this.placeholderedInput,
    required this.mappings,
    required this.createdAt,
    required this.props,
    this.titleMode = SessionTitleMode.auto,
    this.placeholderedOutputCache,
    this.editedOutputCache,
    DateTime? lastOpenedAt,
    DateTime? updatedAt,
    this.archived = false,
    this.schemaVersion = 1,
  })  : lastOpenedAt = lastOpenedAt ?? createdAt,
        updatedAt = updatedAt ?? createdAt;

  void touchOpened() {
    lastOpenedAt = DateTime.now();
    save();
  }

  void touchUpdated() {
    updatedAt = DateTime.now();
    save();
  }
}
