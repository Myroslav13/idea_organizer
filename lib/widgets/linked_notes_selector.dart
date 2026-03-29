import 'package:flutter/material.dart';
import '../models/note_model.dart';

/// Віджет для вибору зв'язаних нотаток (MultiSelect)
class LinkedNotesSelector extends StatelessWidget {
  final List<Note> allNotes;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  final int? maxLinks;

  const LinkedNotesSelector({
    super.key,
    required this.allNotes,
    required this.selectedIds,
    required this.onChanged,
    this.maxLinks,
  });

  @override
  Widget build(BuildContext context) {
    if (allNotes.isEmpty) {
      return const Text('Немає інших нотаток для зв’язку');
    }
    return Wrap(
      spacing: 8.0,
      children: allNotes.map((note) {
        final selected = selectedIds.contains(note.id);
        final disabled = !selected && maxLinks != null && selectedIds.length >= maxLinks!;
        return FilterChip(
          label: Text(note.title),
          selected: selected,
          onSelected: disabled
              ? null
              : (val) {
                  final newIds = List<String>.from(selectedIds);
                  if (val) {
                    newIds.add(note.id);
                  } else {
                    newIds.remove(note.id);
                  }
                  onChanged(newIds);
                },
          disabledColor: Colors.grey[300],
        );
      }).toList(),
    );
  }
}