import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/bloc/notes_bloc.dart';
import 'package:my_app/models/note_model.dart';
import 'package:my_app/repositories/notes_repository.dart';

class FakeNotesRepository implements NotesRepository {
  final StreamController<List<Note>> _controller =
    StreamController<List<Note>>.broadcast();

  bool throwOnAdd = false;
  bool throwOnUpdate = false;
  bool throwOnDelete = false;

  Note? addedNote;
  final List<Note> updatedNotes = [];
  String? deletedId;

  void emitNotes(List<Note> notes) => _controller.add(notes);

  @override
  Stream<List<Note>> getNotesStream() => _controller.stream;

  @override
  Future<void> addNote(Note note) async {
    if (throwOnAdd) {
      throw Exception('add failed');
    }
    addedNote = note;
  }

  @override
  Future<void> updateNote(Note note) async {
    if (throwOnUpdate) {
      throw Exception('update failed');
    }
    updatedNotes.add(note);
  }

  @override
  Future<void> deleteNote(String id) async {
    if (throwOnDelete) {
      throw Exception('delete failed');
    }
    deletedId = id;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

Note buildNote({
  required String id,
  required String title,
  required String content,
  required List<String> tags,
  List<int>? tagsColors,
  List<String> linkedNoteIds = const [],
}) {
  return Note(
    id: id,
    title: title,
    content: content,
    lastChange: '20.04.26, 10:00',
    tags: tags,
    tagsColors: tagsColors ?? tags.map(getColorForTag).toList(),
    linkedNoteIds: linkedNoteIds,
  );
}

void main() {
  group('NotesBloc unit tests', () {
    late FakeNotesRepository repository;
    late NotesBloc bloc;

    setUp(() {
      repository = FakeNotesRepository();
      bloc = NotesBloc(notesRepository: repository);
    });

    tearDown(() async {
      await bloc.close();
      await repository.dispose();
    });

    test('getColorForTag returns predefined color for known tag', () {
      expect(getColorForTag('#idea'), 0xFFFF0000);
      expect(getColorForTag('#finance'), 0xFFFF00FF);
    });

    test('getColorForTag is deterministic for dynamic tags', () {
      final first = getColorForTag('#customTag');
      final second = getColorForTag('#customTag');

      expect(first, second);
      expect(dynamicTagColors, contains(first));
    });

    test('LoadNotes emits loading then loaded when stream provides data', () async {
      final notes = [
        buildNote(id: '1', title: 'A', content: 'Alpha', tags: ['#idea']),
      ];

      final expected = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<NotesLoading>(),
          isA<NotesLoaded>().having(
            (state) => state.allNotes.length,
            'allNotes length',
            1,
          ),
        ]),
      );

      bloc.add(LoadNotes());
      await Future<void>.delayed(Duration.zero);
      repository.emitNotes(notes);

      await expected;
    });

    test('NotesUpdated recalculates tag counts', () async {
      final notes = [
        buildNote(id: '1', title: 'A', content: 'Alpha', tags: ['#idea']),
        buildNote(id: '2', title: 'B', content: 'Beta', tags: ['#idea', '#finance']),
      ];

      bloc.add(NotesUpdated(notes));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<NotesLoaded>());
      expect(bloc.state.tagCounts['#idea'], 2);
      expect(bloc.state.tagCounts['#finance'], 1);
    });

    test('FilterBySearch filters by title and content', () async {
      final notes = [
        buildNote(id: '1', title: 'Launch plan', content: 'Roadmap', tags: ['#startup']),
        buildNote(id: '2', title: 'Budget', content: 'Marketing launch', tags: ['#finance']),
      ];

      bloc.add(NotesUpdated(notes));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const FilterBySearch('launch'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.displayedNotes.length, 2);
      expect(bloc.state.searchTerm, 'launch');
    });

    test('FilterByTag toggles selected tag', () async {
      final notes = [
        buildNote(id: '1', title: 'A', content: 'x', tags: ['#idea']),
        buildNote(id: '2', title: 'B', content: 'y', tags: ['#finance']),
      ];

      bloc.add(NotesUpdated(notes));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const FilterByTag('#idea'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.selectedTag, '#idea');
      expect(bloc.state.displayedNotes.map((n) => n.id), ['1']);

      bloc.add(const FilterByTag('#idea'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.selectedTag, isNull);
      expect(bloc.state.displayedNotes.length, 2);
    });

    test('AddNote sends new note to repository', () async {
      bloc.add(
        const AddNote(
          title: 'New idea',
          content: 'Test content',
          tags: ['#idea', '#custom'],
        ),
      );

      await Future<void>.delayed(Duration.zero);

      final saved = repository.addedNote;
      expect(saved, isNotNull);
      expect(saved!.title, 'New idea');
      expect(saved.content, 'Test content');
      expect(saved.tags, ['#idea', '#custom']);
      expect(saved.tagsColors, [getColorForTag('#idea'), getColorForTag('#custom')]);
      expect(saved.lastChange, isNotEmpty);
    });

    test('AddNote emits NotesError when repository fails', () async {
      repository.throwOnAdd = true;

      final expected = expectLater(
        bloc.stream,
        emits(isA<NotesError>().having((state) => state.message, 'message', contains('Failed to add note'))),
      );

      bloc.add(
        const AddNote(
          title: 'Bad note',
          content: 'Will fail',
          tags: ['#idea'],
        ),
      );

      await expected;
    });

    test('UpdateNoteLinks updates note and creates reverse link', () async {
      final noteA = buildNote(
        id: '1',
        title: 'A',
        content: 'Alpha',
        tags: ['#idea'],
      );
      final noteB = buildNote(
        id: '2',
        title: 'B',
        content: 'Beta',
        tags: ['#finance'],
      );

      bloc.add(NotesUpdated([noteA, noteB]));
      await Future<void>.delayed(Duration.zero);

      bloc.add(
        UpdateNoteLinks(
          updatedNote: noteA.copyWith(linkedNoteIds: ['2']),
          allLinkedIds: const ['2'],
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(repository.updatedNotes.length, 2);
      expect(repository.updatedNotes.first.id, '1');
      expect(repository.updatedNotes.last.id, '2');
      expect(repository.updatedNotes.last.linkedNoteIds, contains('1'));
    });
  });
}
