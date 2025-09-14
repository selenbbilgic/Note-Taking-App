import 'package:notes_app/data/api_client.dart';
import 'package:notes_app/data/models/note.dart';
import 'package:notes_app/data/repositories/notes_repository.dart';

class RemoteNotesRepository implements NotesRepository {
  final ApiClient api;
  RemoteNotesRepository(this.api);

  @override
  Future<List<Note>> fetchNotes() async {
    print('[RemoteNotesRepository] Starting fetchNotes...');
    try {
      final res = await api.getNotes();
      print('[RemoteNotesRepository] API response status: ${res.statusCode}');
      print('[RemoteNotesRepository] API response data: ${res.data}');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final notes = list.map(Note.fromJson).toList();
      print('[RemoteNotesRepository] Parsed ${notes.length} notes');
      return notes;
    } catch (e) {
      print('[RemoteNotesRepository] Error in fetchNotes: $e');
      rethrow;
    }
  }

  @override
  Future<Note> create(
    String title,
    String content, {
    bool pinned = false,
  }) async {
    try {
      final res = await api.createNote(title, content, pinned: pinned);
      return Note.fromJson(Map<String, dynamic>.from(res.data));
    } catch (e) {
      print('[RemoteNotesRepository] Error creating note: $e');
      rethrow;
    }
  }

  @override
  Future<Note> update(
    String id, {
    String? title,
    String? content,
    bool? pinned,
  }) async {
    try {
      final res = await api.updateNote(
        id,
        title: title,
        content: content,
        pinned: pinned,
      );
      return Note.fromJson(Map<String, dynamic>.from(res.data));
    } catch (e) {
      print('[RemoteNotesRepository] Error updating note: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await api.deleteNote(id);
    } catch (e) {
      print('[RemoteNotesRepository] Error deleting note: $e');
      rethrow;
    }
  }
}
