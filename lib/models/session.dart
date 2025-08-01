import 'package:redactly/models/placeholder_mapping.dart';

class Session {
  final String id;
  final String title;
  final String content;
  final List<PlaceholderMapping> mappings;
  final DateTime createdAt;

  Session({
    required this.id,
    required this.title,
    required this.content,
    required this.mappings,
    required this.createdAt,
  });

  Session copyWith({
    String? id,
    String? title,
    String? content,
    List<PlaceholderMapping>? mappings,
    DateTime? createdAt,
  }) {
    return Session(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mappings: mappings ?? this.mappings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}