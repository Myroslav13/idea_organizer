part of 'notes_bloc.dart';
// Двостороннє оновлення зв'язків між нотатками
class UpdateNoteLinks extends NotesEvent {
  final Note updatedNote;
  final List<String> allLinkedIds;
  const UpdateNoteLinks({required this.updatedNote, required this.allLinkedIds});
  @override
  List<Object> get props => [updatedNote, allLinkedIds];
}

abstract class NotesEvent extends Equatable {
  const NotesEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotes extends NotesEvent {}

// Отримання нових даних зі Stream
class NotesUpdated extends NotesEvent {
  final List<Note> notes;
  const NotesUpdated(this.notes);
  @override
  List<Object?> get props => [notes];
}

class AddNote extends NotesEvent {
  final String title;
  final String content;
  final List<String> tags;
  final DateTime? notificationDate;
  final List<String> linkedNoteIds;

  const AddNote({
    required this.title,
    required this.content,
    required this.tags,
    this.notificationDate,
    this.linkedNoteIds = const [],
  });
  @override
  List<Object?> get props => [title, content, tags, notificationDate, linkedNoteIds];
}

class UpdateNote extends NotesEvent {
  final Note updatedNote;
  const UpdateNote(this.updatedNote);
  @override
  List<Object> get props => [updatedNote];
}

class DeleteNote extends NotesEvent {
  final Note noteToDelete;
  const DeleteNote(this.noteToDelete);
  @override
  List<Object> get props => [noteToDelete];
}

class FilterBySearch extends NotesEvent {
  final String searchTerm;
  const FilterBySearch(this.searchTerm);
  @override
  List<Object?> get props => [searchTerm];
}

class FilterByTag extends NotesEvent {
  final String tag;
  const FilterByTag(this.tag);
  @override
  List<Object?> get props => [tag];
}