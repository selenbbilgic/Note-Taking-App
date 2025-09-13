import 'package:notes_app/services/api_client.dart';
import 'package:notes_app/models/note.dart';

class NotesService {
  final ApiClient api;
  NotesService(this.api);

  Future<List<Note>> list() async {
    final res = await api.getNotes();
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Note.fromJson).toList();
  }

  Future<Note> create(String title, String content) async {
    final res = await api.createNote(title, content);
    return Note.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<Note> update(String id, {String? title, String? content}) async {
    final res = await api.updateNote(id, title: title, content: content);
    return Note.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> delete(String id) async {
    await api.deleteNote(id);
  }

  Future<Note> togglePin(Note note) async {
    final res = await api.updateNote(note.id, pinned: !note.pinned);
    return Note.fromJson(Map<String, dynamic>.from(res.data));
  }
}
