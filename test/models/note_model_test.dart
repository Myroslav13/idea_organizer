import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/note_model.dart';

void main() {
  group('Note model tests', () {
    const baseNote = Note(
      id: 'n1',
      title: 'Title',
      content: 'Content',
      lastChange: '20.04.26, 10:00',
      tags: ['#idea', '#finance'],
      tagsColors: [0xFFFF0000, 0xFFFF00FF],
      linkedNoteIds: ['n2'],
    );

    test('supports value equality via Equatable', () {
      const sameNote = Note(
        id: 'n1',
        title: 'Title',
        content: 'Content',
        lastChange: '20.04.26, 10:00',
        tags: ['#idea', '#finance'],
        tagsColors: [0xFFFF0000, 0xFFFF00FF],
        linkedNoteIds: ['n2'],
      );

      expect(baseNote, equals(sameNote));
    });

    test('copyWith updates only provided fields', () {
      final updated = baseNote.copyWith(
        title: 'Updated title',
        tags: const ['#startup'],
      );

      expect(updated.id, 'n1');
      expect(updated.title, 'Updated title');
      expect(updated.content, 'Content');
      expect(updated.tags, ['#startup']);
      expect(updated.tagsColors, [0xFFFF0000, 0xFFFF00FF]);
      expect(updated.linkedNoteIds, ['n2']);
    });

    test('toDocument maps all primitive fields', () {
      final map = baseNote.toDocument();

      expect(map['title'], 'Title');
      expect(map['content'], 'Content');
      expect(map['lastChange'], '20.04.26, 10:00');
      expect(map['tags'], ['#idea', '#finance']);
      expect(map['tagsColors'], [0xFFFF0000, 0xFFFF00FF]);
      expect(map['linkedNoteIds'], ['n2']);
      expect(map['notificationDate'], isNull);
    });

    test('toDocument converts notificationDate to Timestamp', () {
      final date = DateTime(2026, 4, 20, 15, 30);
      final note = baseNote.copyWith(notificationDate: date);

      final map = note.toDocument();

      expect(map['notificationDate'], isA<Timestamp>());
      final timestamp = map['notificationDate'] as Timestamp;
      expect(timestamp.toDate(), date);
    });

    test('copyWith keeps existing notificationDate when null is passed', () {
      final date = DateTime(2026, 4, 20, 12, 0);
      final noteWithDate = baseNote.copyWith(notificationDate: date);

      final updated = noteWithDate.copyWith(notificationDate: null);

      expect(updated.notificationDate, date);
    });
  });
}
