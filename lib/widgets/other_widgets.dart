import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/notes_bloc.dart';
import '../models/note_model.dart';
import 'linked_notes_selector.dart';

Widget buildListItem(
    BuildContext context, {
      required String color,
      required String title,
      required int number,
      required bool isSelected,
      required VoidCallback onTap,
    }) {
  final int colorValue = int.parse(
    color.startsWith('0x') ? color.substring(2) : color,
    radix: 16,
  );

  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 2.0),
    leading: Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Color(colorValue),
        shape: BoxShape.circle,
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        fontFamily: "Inter",
        color: Colors.black,
      ),
    ),
    trailing: SizedBox(
      width: 45,
      height: 24,
      child: Container(
        decoration: BoxDecoration(
          color: Color(colorValue),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
    selected: isSelected,
    selectedTileColor: Color(colorValue).withOpacity(0.2),
    onTap: onTap,
  );
}

Widget buildContentBlock({
  required String title,
  required String content,
  required String lastChange,
  required List<String> tags,
  required List<int> tagsColors,
  List<Note>? linkedNotes,
}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: 500,
      minHeight: 260,
    ),
    child: Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: Colors.grey,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 30.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 24.0,
              runSpacing: 16.0,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 36),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Wrap(
                        spacing: 20.0,
                        runSpacing: 8.0,
                        children: List.generate(tags.length, (index) {
                          if (index >= tagsColors.length) {
                            return const SizedBox.shrink();
                          }
                          return SizedBox(
                            width: 130,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(tagsColors[index]),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                tags[index],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Last change",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF898989)),
                    ),
                    Text(
                      lastChange,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF898989)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              content,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF898989)),
              overflow: TextOverflow.ellipsis,
              maxLines: 5,
            ),
            if (linkedNotes != null && linkedNotes.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Зв’язані нотатки:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF007BFF)),
              ),
              Wrap(
                spacing: 8.0,
                children: linkedNotes.map((note) => Chip(
                  label: Text(note.title),
                  backgroundColor: const Color(0xFFE3F2FD),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class NoteFormDialog extends StatefulWidget {
  final Note? noteToEdit;

  const NoteFormDialog({super.key, this.noteToEdit});

  @override
  State<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends State<NoteFormDialog> {
  List<String> _selectedLinkedNoteIds = [];

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _tagsController;
  late TextEditingController _dateController;
  late TextEditingController _ideaController;

  final Set<String> _selectedTags = {};

  DateTime? _selectedDate;
  bool get _isEditing => widget.noteToEdit != null;

  @override
  void initState() {
    super.initState();

    final note = widget.noteToEdit;
    _titleController = TextEditingController(text: note?.title ?? '');

    if (note != null && note.tags.isNotEmpty) {
      _selectedTags.addAll(note.tags);
    }
    _tagsController = TextEditingController(text: _selectedTags.join(', '));
    _ideaController = TextEditingController(text: note?.content ?? '');
    _dateController = TextEditingController();

    if (note != null && note.notificationDate != null) {
      _selectedDate = note.notificationDate;
      _dateController.text =
          DateFormat('dd.MM.yyyy').format(_selectedDate!);
    }

    if (note != null) {
      final allNotes = context.read<NotesBloc>().state.allNotes;
      final linked = <String>{};
      linked.addAll(note.linkedNoteIds);
      linked.addAll(allNotes.where((n) => n.linkedNoteIds.contains(note.id)).map((n) => n.id));
      _selectedLinkedNoteIds = linked.toList();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().toLocal(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _dateController.dispose();
    _ideaController.dispose();
    super.dispose();
  }

  void _updateTagsController() {
    setState(() {
      _tagsController.text = _selectedTags.join(', ');
    });
  }

  void _updateTagsSetFromText() {
    final tagsFromText = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty);
    setState(() {
      _selectedTags.clear();
      _selectedTags.addAll(tagsFromText);
    });
  }

  void _onCompletePressed() {
    if (_formKey.currentState!.validate()) {
      _updateTagsSetFromText();
      final tagsList = _selectedTags.toList();
      context.read<NotesBloc>().add(
        AddNote(
          title: _titleController.text,
          content: _ideaController.text,
          tags: tagsList,
          notificationDate: _selectedDate,
          linkedNoteIds: _selectedLinkedNoteIds,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  void _onEditPressed() {
    if (_formKey.currentState!.validate()) {
      _updateTagsSetFromText();
      final tagsList = _selectedTags.toList();

      final newTagsColors = tagsList.map((tag) => getColorForTag(tag)).toList();

      final String realLastChange =
      DateFormat('dd.MM.yy, HH:mm').format(DateTime.now().toLocal());

      final updatedNote = widget.noteToEdit!.copyWith(
        title: _titleController.text,
        content: _ideaController.text,
        tags: tagsList,
        tagsColors: newTagsColors,
        lastChange: realLastChange,
        notificationDate: _selectedDate,
        linkedNoteIds: _selectedLinkedNoteIds,
      );

      context.read<NotesBloc>().add(UpdateNoteLinks(
        updatedNote: updatedNote,
        allLinkedIds: _selectedLinkedNoteIds,
      ));
      Navigator.of(context).pop();
    }
  }

  void _onDeletePressed() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () {
              context.read<NotesBloc>().add(DeleteNote(widget.noteToEdit!));
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Title",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: "Title",
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Зв’язані нотатки",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                BlocBuilder<NotesBloc, NotesState>(
                  builder: (context, state) {
                    final allNotes = state.allNotes.where((n) => n.id != widget.noteToEdit?.id).toList();
                    return LinkedNotesSelector(
                      allNotes: allNotes,
                      selectedIds: _selectedLinkedNoteIds,
                      onChanged: (ids) {
                        if (ids.length <= 2) {
                          setState(() {
                            _selectedLinkedNoteIds = ids;
                          });
                        }
                      },
                      maxLinks: 2,
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  "Tags",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: mainTagColors.keys.map((tagName) {
                    final isSelected = _selectedTags.contains(tagName);

                    return FilterChip(
                      label: Text(tagName),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tagName);
                          } else {
                            _selectedTags.remove(tagName);
                          }
                          _updateTagsController();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    hintText: "Or type manually (e.g. #new, #custom)",
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Please enter at least one tag'
                      : null,
                  onChanged: (text) {
                    _updateTagsSetFromText();
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  "Notification date",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    hintText: "Choose date",
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () {
                    _selectDate(context);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  "Idea",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ideaController,
                  decoration: const InputDecoration(
                    hintText: "Idea",
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 5,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Please describe your idea'
                      : null,
                ),
                const SizedBox(height: 24),
                if (_isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onDeletePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            "Delete",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onEditPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            "Edit",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _onCompletePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        "Complete",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}