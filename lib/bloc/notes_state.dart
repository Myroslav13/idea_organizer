part of 'notes_bloc.dart';

abstract class NotesState extends Equatable {
  final List<Note> allNotes;
  final List<Note> displayedNotes;
  final Map<String, int> tagCounts;
  final String? selectedTag;
  final String searchTerm;

  const NotesState({
    this.allNotes = const [],
    this.displayedNotes = const [],
    this.tagCounts = const {},
    this.selectedTag,
    this.searchTerm = '',
  });

  @override
  List<Object?> get props => [
    allNotes,
    displayedNotes,
    tagCounts,
    selectedTag,
    searchTerm,
  ];
}

class NotesInitial extends NotesState {}

class NotesLoading extends NotesState {
  const NotesLoading({
    required List<Note> previousAllNotes,
    required List<Note> previousDisplayedNotes,
    required Map<String, int> previousTagCounts,
    String? previousSelectedTag,
    String previousSearchTerm = '',
  }) : super(
    allNotes: previousAllNotes,
    displayedNotes: previousDisplayedNotes,
    tagCounts: previousTagCounts,
    selectedTag: previousSelectedTag,
    searchTerm: previousSearchTerm,
  );
}

class NotesLoaded extends NotesState {
  const NotesLoaded({
    required List<Note> allNotes,
    required List<Note> displayedNotes,
    required Map<String, int> tagCounts,
    String? selectedTag,
    String searchTerm = '',
  }) : super(
    allNotes: allNotes,
    displayedNotes: displayedNotes,
    tagCounts: tagCounts,
    selectedTag: selectedTag,
    searchTerm: searchTerm,
  );
}

class NotesError extends NotesState {
  final String message;
  const NotesError({
    required this.message,
    required List<Note> previousAllNotes,
    required List<Note> previousDisplayedNotes,
    required Map<String, int> previousTagCounts,
    String? previousSelectedTag,
    String previousSearchTerm = '',
  }) : super(
    allNotes: previousAllNotes,
    displayedNotes: previousDisplayedNotes,
    tagCounts: previousTagCounts,
    selectedTag: previousSelectedTag,
    searchTerm: previousSearchTerm,
  );

  @override
  List<Object?> get props => [
    message,
    allNotes,
    displayedNotes,
    tagCounts,
    selectedTag,
    searchTerm,
  ];
}