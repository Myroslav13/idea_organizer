import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note_model.dart';

abstract class NotesRepository {
  Stream<List<Note>> getNotesStream();
  Future<void> addNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String id);
}

class FirestoreNotesRepository implements NotesRepository {
  final FirebaseFirestore _firestore;

  FirestoreNotesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Отримуємо шлях до колекції нотаток поточного користувача
  CollectionReference _getNotesCollection() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(userId).collection('notes');
  }

  @override
  Stream<List<Note>> getNotesStream() {
    try {
      return _getNotesCollection()
          .orderBy('lastChange', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Note.fromSnapshot(doc)).toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  @override
  Future<void> addNote(Note note) async {
    await _getNotesCollection().add(note.toDocument());
  }

  @override
  Future<void> updateNote(Note note) async {
    await _getNotesCollection().doc(note.id).update(note.toDocument());
  }

  @override
  Future<void> deleteNote(String id) async {
    await _getNotesCollection().doc(id).delete();
  }
}