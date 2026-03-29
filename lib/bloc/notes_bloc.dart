import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../repositories/notes_repository.dart';

part 'notes_event.dart';
part 'notes_state.dart';

const Map<String, String> mainTagColors = {
  "#idea": "0xFFFF0000",
  "#finance": "0xFFFF00FF",
  "#marketing": "0xFF0000FF",
  "#inspiration": "0xFFFF9500",
  "#startup": "0xFF13A600",
};

const List<int> dynamicTagColors = [
  0xFFFF0000, 0xFFFF00FF, 0xFF0000FF, 0xFFFF9500, 0xFF13A600, 0xFF00ACC1, 0xFF7E57C2,
];

int getColorForTag(String tag) {
  final mainColorString = mainTagColors[tag];
  if (mainColorString != null) {
    return int.parse(mainColorString.substring(2), radix: 16);
  }
  final int hashCode = tag.hashCode.abs();
  final int colorIndex = hashCode % dynamicTagColors.length;
  return dynamicTagColors[colorIndex];
}

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRepository _notesRepository;
  StreamSubscription? _notesSubscription;

  NotesBloc({required NotesRepository notesRepository})
      : _notesRepository = notesRepository,
        super(NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<NotesUpdated>(_onNotesUpdated);
    on<AddNote>(_onAddNote);
    on<UpdateNote>(_onUpdateNote);
    on<UpdateNoteLinks>(_onUpdateNoteLinks);
    on<DeleteNote>(_onDeleteNote);
    on<FilterBySearch>(_onFilterBySearch);
    on<FilterByTag>(_onFilterByTag);
  }

  Future<void> _onUpdateNoteLinks(UpdateNoteLinks event, Emitter<NotesState> emit) async {
    try {
      // Оновлюємо саму нотатку
      await _notesRepository.updateNote(event.updatedNote);

      // Оновлюємо зв’язані нотатки (додаємо або видаляємо зв’язок з ними)
      final allNotes = state.allNotes;
      final updatedId = event.updatedNote.id;
      final newLinkedIds = event.allLinkedIds;

      for (final note in allNotes) {
        if (note.id == updatedId) continue;
        final isLinkedNow = newLinkedIds.contains(note.id);
        final wasLinked = note.linkedNoteIds.contains(updatedId);

        if (isLinkedNow && !wasLinked) {
          // Додаємо зв’язок у іншій нотатці
          final updated = note.copyWith(
            linkedNoteIds: [...note.linkedNoteIds, updatedId],
          );
          await _notesRepository.updateNote(updated);
        } else if (!isLinkedNow && wasLinked) {
          // Видаляємо зв’язок у іншій нотатці
          final updated = note.copyWith(
            linkedNoteIds: note.linkedNoteIds.where((id) => id != updatedId).toList(),
          );
          await _notesRepository.updateNote(updated);
        }
      }
    } catch (e) {
      emit(NotesError(
        message: 'Failed to update links: $e',
        previousAllNotes: state.allNotes,
        previousDisplayedNotes: state.displayedNotes,
        previousTagCounts: state.tagCounts,
        previousSelectedTag: state.selectedTag,
        previousSearchTerm: state.searchTerm,
      ));
    }
  }

  Map<String, int> _calculateTagCounts(List<Note> notes) {
    final Map<String, int> counts = {};
    for (final note in notes) {
      for (final tag in note.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<Note> _applyFilters(List<Note> allNotes, String? selectedTag, String searchTerm) {
    List<Note> filteredNotes = List.from(allNotes);
    if (selectedTag != null) {
      filteredNotes = filteredNotes.where((note) => note.tags.contains(selectedTag)).toList();
    }
    if (searchTerm.isNotEmpty) {
      final lowerSearchTerm = searchTerm.toLowerCase();
      filteredNotes = filteredNotes.where((note) {
        final titleMatch = note.title.toLowerCase().contains(lowerSearchTerm);
        final contentMatch = note.content.toLowerCase().contains(lowerSearchTerm);
        return titleMatch || contentMatch;
      }).toList();
    }
    return filteredNotes;
  }

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NotesState> emit) async {
    emit(NotesLoading(
      previousAllNotes: state.allNotes,
      previousDisplayedNotes: state.displayedNotes,
      previousTagCounts: state.tagCounts,
      previousSelectedTag: state.selectedTag,
      previousSearchTerm: state.searchTerm,
    ));

    await _notesSubscription?.cancel();
    _notesSubscription = _notesRepository.getNotesStream().listen(
            (notes) => add(NotesUpdated(notes)),
        onError: (error) {
          print("Stream Error: $error");
        }
    );
  }

  void _onNotesUpdated(NotesUpdated event, Emitter<NotesState> emit) {
    final tagCounts = _calculateTagCounts(event.notes);
    final displayedNotes = _applyFilters(
      event.notes,
      state.selectedTag,
      state.searchTerm,
    );

    emit(NotesLoaded(
      allNotes: event.notes,
      displayedNotes: displayedNotes,
      tagCounts: tagCounts,
      selectedTag: state.selectedTag,
      searchTerm: state.searchTerm,
    ));
  }

  Future<void> _onAddNote(AddNote event, Emitter<NotesState> emit) async {
    try {
      final newTags = event.tags;
      final newTagsColors = newTags.map((tag) => getColorForTag(tag)).toList();
      final String realLastChange = DateFormat('dd.MM.yy, HH:mm').format(DateTime.now().toLocal());

      final newNote = Note(
        id: '',
        title: event.title,
        content: event.content,
        tags: newTags,
        lastChange: realLastChange,
        tagsColors: newTagsColors,
        notificationDate: event.notificationDate,
      );

      await _notesRepository.addNote(newNote);
    } catch (e) {
      emit(NotesError(
        message: 'Failed to add note: $e',
        previousAllNotes: state.allNotes,
        previousDisplayedNotes: state.displayedNotes,
        previousTagCounts: state.tagCounts,
        previousSelectedTag: state.selectedTag,
        previousSearchTerm: state.searchTerm,
      ));
    }
  }

  Future<void> _onUpdateNote(UpdateNote event, Emitter<NotesState> emit) async {
    try {
      await _notesRepository.updateNote(event.updatedNote);
    } catch (e) {
      emit(NotesError(
        message: 'Failed to update note: $e',
        previousAllNotes: state.allNotes,
        previousDisplayedNotes: state.displayedNotes,
        previousTagCounts: state.tagCounts,
        previousSelectedTag: state.selectedTag,
        previousSearchTerm: state.searchTerm,
      ));
    }
  }

  Future<void> _onDeleteNote(DeleteNote event, Emitter<NotesState> emit) async {
    try {
      await _notesRepository.deleteNote(event.noteToDelete.id);
    } catch (e) {
      emit(NotesError(
        message: 'Failed to delete note: $e',
        previousAllNotes: state.allNotes,
        previousDisplayedNotes: state.displayedNotes,
        previousTagCounts: state.tagCounts,
        previousSelectedTag: state.selectedTag,
        previousSearchTerm: state.searchTerm,
      ));
    }
  }

  void _onFilterBySearch(FilterBySearch event, Emitter<NotesState> emit) {
    final displayedNotes = _applyFilters(
      state.allNotes,
      state.selectedTag,
      event.searchTerm,
    );
    emit(NotesLoaded(
      allNotes: state.allNotes,
      displayedNotes: displayedNotes,
      tagCounts: state.tagCounts,
      selectedTag: state.selectedTag,
      searchTerm: event.searchTerm,
    ));
  }

  void _onFilterByTag(FilterByTag event, Emitter<NotesState> emit) {
    final newSelectedTag = state.selectedTag == event.tag ? null : event.tag;
    final displayedNotes = _applyFilters(
      state.allNotes,
      newSelectedTag,
      state.searchTerm,
    );
    emit(NotesLoaded(
      allNotes: state.allNotes,
      displayedNotes: displayedNotes,
      tagCounts: state.tagCounts,
      selectedTag: newSelectedTag,
      searchTerm: state.searchTerm,
    ));
  }

  @override
  Future<void> close() {
    _notesSubscription?.cancel();
    return super.close();
  }
}