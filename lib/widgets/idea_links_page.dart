import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notes_bloc.dart';
import '../models/note_model.dart';

class IdeaLinksPage extends StatelessWidget {
  const IdeaLinksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC3CFE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC3CFE2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Зв'язки між ідеями",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          final notes = state.allNotes;
          if (notes.isEmpty) {
            return const Center(child: Text("Немає нотаток для візуалізації"));
          }
          // 1. Будуємо всі ланцюжки (суцільні послідовності)
          final Set<String> visited = {};
          final List<List<Note>> chains = [];
          final Map<String, Note> noteMap = { for (var n in notes) n.id: n };

          // Для кожної нотатки, яка ще не відвідана і має зв’язки, будуємо ланцюжок
          for (final note in notes) {
            if (visited.contains(note.id)) continue;
            // Має хоча б один зв’язок
            final neighbors = <String>{
              ...note.linkedNoteIds,
              ...notes.where((n) => n.linkedNoteIds.contains(note.id)).map((n) => n.id),
            };
            if (neighbors.isEmpty) continue;

            // Будуємо ланцюжок вперед
            final List<Note> chain = [note];
            visited.add(note.id);
            Note? current = note;
            while (true) {
              final nextId = current!.linkedNoteIds.firstWhere(
                (id) => !visited.contains(id),
                orElse: () => '',
              );
              if (nextId.isEmpty || !noteMap.containsKey(nextId)) break;
              final next = noteMap[nextId]!;
              chain.add(next);
              visited.add(next.id);
              current = next;
            }

            // Будуємо ланцюжок назад
            current = note;
            while (true) {
              final prevList = notes.where(
                (n) => n.linkedNoteIds.contains(current!.id) && !visited.contains(n.id),
              ).toList();
              if (prevList.isEmpty) break;
              final prev = prevList.first;
              chain.insert(0, prev);
              visited.add(prev.id);
              current = prev;
            }

            chains.add(chain);
          }

          if (chains.isEmpty) {
            return const Center(child: Text("Немає зв'язків для візуалізації"));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Візуалізація",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  ...chains.map((chain) => Column(
                    children: [
                      ...List.generate(chain.length, (i) => Column(
                        children: [
                          _IdeaLinkCard(note: chain[i], allNotes: notes),
                          if (i != chain.length - 1)
                            Container(
                              width: 2,
                              height: 32,
                              color: const Color(0xFF007BFF),
                            ),
                        ],
                      )),
                      const SizedBox(height: 32),
                    ],
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IdeaLinkCard extends StatelessWidget {
  final Note note;
  final List<Note> allNotes;

  const _IdeaLinkCard({required this.note, required this.allNotes});

  @override
  Widget build(BuildContext context) {
    final tags = note.tags;
    final tagsColors = note.tagsColors;
    // Кількість унікальних сусідів (двосторонньо)
    final outgoing = note.linkedNoteIds;
    final incoming = allNotes.where((n) => n.linkedNoteIds.contains(note.id)).map((n) => n.id);
    final linkedCount = {...outgoing, ...incoming}.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF007BFF), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(tags.length, (i) {
              return Chip(
                label: Text(tags[i], style: const TextStyle(color: Colors.white)),
                backgroundColor: Color(tagsColors.length > i ? tagsColors[i] : 0xFF007BFF),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 8),
          Text(
            "Зв'язків: $linkedCount",
            style: const TextStyle(color: Color(0xFF007BFF), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}