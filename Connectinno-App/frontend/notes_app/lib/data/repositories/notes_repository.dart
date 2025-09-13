import 'package:notes_app/data/api_client.dart';
import 'package:notes_app/data/models/note.dart';

class NotesRepository {
  final ApiClient api;
  NotesRepository(this.api);

  Future<List<Note>> fetchNotes() async {
    final res = await api.getNotes();
    final list = (res.data as List).cast<Map<String, dynamic>>();
    final notes = list.map(Note.fromJson).toList();
    // client-side sort: pinned first, then newest
    notes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return notes;
  }

  Future<Note> create(
    String title,
    String content, {
    bool pinned = false,
  }) async {
    final res = await api.createNote(title, content, pinned: pinned);
    return Note.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<Note> update(
    String id, {
    String? title,
    String? content,
    bool? pinned,
  }) async {
    final res = await api.updateNote(
      id,
      title: title,
      content: content,
      pinned: pinned,
    );
    return Note.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> delete(String id) => api.deleteNote(id);
}
