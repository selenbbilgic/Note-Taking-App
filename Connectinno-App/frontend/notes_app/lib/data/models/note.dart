import 'dart:math';

import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.pinned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.temp({required String title, required String content}) {
    final cid =
        'client_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 32)}';
    final now = DateTime.now().toUtc();
    return Note(
      id: cid,
      title: title,
      content: content,
      pinned: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'pinned': pinned,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  static Note fromJson(Map<String, dynamic> m) => Note(
    id: m['id'] as String,
    title: (m['title'] ?? '') as String,
    content: (m['content'] ?? '') as String,
    pinned: (m['pinned'] ?? false) as bool,
    createdAt: DateTime.parse(m['created_at'] as String).toUtc(),
    updatedAt: DateTime.parse(m['updated_at'] as String).toUtc(),
  );

  Note copyWith({
    String? title,
    String? content,
    bool? pinned,
    DateTime? updatedAt,
  }) => Note(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    pinned: pinned ?? this.pinned,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, title, content, pinned, createdAt, updatedAt];
}
