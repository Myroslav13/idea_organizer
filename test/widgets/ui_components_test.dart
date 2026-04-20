import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/bloc/notes_bloc.dart';
import 'package:my_app/models/note_model.dart';
import 'package:my_app/repositories/notes_repository.dart';
import 'package:my_app/widgets/linked_notes_selector.dart';
import 'package:my_app/widgets/other_widgets.dart';

class FakeNotesRepository implements NotesRepository {
  final StreamController<List<Note>> _controller =
    StreamController<List<Note>>.broadcast();

  Note? addedNote;

  @override
  Stream<List<Note>> getNotesStream() => _controller.stream;

  @override
  Future<void> addNote(Note note) async {
    addedNote = note;
  }

  @override
  Future<void> updateNote(Note note) async {}

  @override
  Future<void> deleteNote(String id) async {}

  Future<void> dispose() async {
    await _controller.close();
  }
}

Note buildNote({
  required String id,
  required String title,
  required String content,
  List<String> tags = const ['#idea'],
  List<String> linked = const [],
}) {
  return Note(
    id: id,
    title: title,
    content: content,
    lastChange: '20.04.26, 10:00',
    tags: tags,
    tagsColors: tags.map(getColorForTag).toList(),
    linkedNoteIds: linked,
  );
}

void main() {
  group('High-level widget tests', () {
    testWidgets('LinkedNotesSelector shows empty state text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LinkedNotesSelector(
              allNotes: [],
              selectedIds: [],
              onChanged: _noop,
            ),
          ),
        ),
      );

      expect(find.text('Немає інших нотаток для зв’язку'), findsOneWidget);
    });

    testWidgets('LinkedNotesSelector returns selected ids on tap', (tester) async {
      List<String> result = [];
      final notes = [
        buildNote(id: '1', title: 'First', content: 'A'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkedNotesSelector(
              allNotes: notes,
              selectedIds: const [],
              onChanged: (ids) => result = ids,
            ),
          ),
        ),
      );

      await tester.tap(find.text('First'));
      await tester.pump();

      expect(result, ['1']);
    });

    testWidgets('buildListItem renders title and count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => buildListItem(
                context,
                color: '0xFF007BFF',
                title: '#idea',
                number: 3,
                isSelected: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('#idea'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('buildContentBlock renders linked notes chips', (tester) async {
      final linkedNotes = [
        buildNote(id: '2', title: 'Related 1', content: 'A'),
        buildNote(id: '3', title: 'Related 2', content: 'B'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildContentBlock(
              title: 'Main note',
              content: 'Main content',
              lastChange: '20.04.26, 10:00',
              tags: const ['#idea'],
              tagsColors: const [0xFF007BFF],
              linkedNotes: linkedNotes,
            ),
          ),
        ),
      );

      expect(find.text('Main note'), findsOneWidget);
      expect(find.text('Зв’язані нотатки:'), findsOneWidget);
      expect(find.text('Related 1'), findsOneWidget);
      expect(find.text('Related 2'), findsOneWidget);
    });

    testWidgets('LinkedNotesSelector disables new selections on maxLinks', (
      tester,
    ) async {
      List<String> selected = ['1'];
      final notes = [
        buildNote(id: '1', title: 'First', content: 'A'),
        buildNote(id: '2', title: 'Second', content: 'B'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkedNotesSelector(
              allNotes: notes,
              selectedIds: selected,
              maxLinks: 1,
              onChanged: (ids) => selected = ids,
            ),
          ),
        ),
      );

      final secondChip = find.widgetWithText(FilterChip, 'Second');
      final filterChip = tester.widget<FilterChip>(secondChip);
      expect(filterChip.onSelected, isNull);
    });

  });
}

void _noop(List<String> _) {}
