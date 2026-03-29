import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final String lastChange;
  final List<String> tags;
  final List<int> tagsColors;
  final DateTime? notificationDate;
  final List<String> linkedNoteIds;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.lastChange,
    required this.tags,
    required this.tagsColors,
    this.notificationDate,
    this.linkedNoteIds = const [],
  });

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    lastChange,
    tags,
    tagsColors,
    notificationDate,
    linkedNoteIds,
  ];

  // Перетворення з Firestore DocumentSnapshot в об'єкт Note
  factory Note.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Note(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      lastChange: data['lastChange'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      tagsColors: List<int>.from(data['tagsColors'] ?? []),
      notificationDate: data['notificationDate'] != null
          ? (data['notificationDate'] as Timestamp).toDate()
          : null,
      linkedNoteIds: List<String>.from(data['linkedNoteIds'] ?? []),
    );
  }

  // Перетворення об'єкта Note в Map для збереження у Firestore
  Map<String, dynamic> toDocument() {
    return {
      'title': title,
      'content': content,
      'lastChange': lastChange,
      'tags': tags,
      'tagsColors': tagsColors,
      'notificationDate': notificationDate != null
          ? Timestamp.fromDate(notificationDate!)
          : null,
      'linkedNoteIds': linkedNoteIds,
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? lastChange,
    List<String>? tags,
    List<int>? tagsColors,
    DateTime? notificationDate,
    List<String>? linkedNoteIds,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      lastChange: lastChange ?? this.lastChange,
      tags: tags ?? this.tags,
      tagsColors: tagsColors ?? this.tagsColors,
      notificationDate: notificationDate ?? this.notificationDate,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
    );
  }
}