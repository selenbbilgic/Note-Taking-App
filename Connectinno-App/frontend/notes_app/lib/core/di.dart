import 'package:notes_app/data/api_client.dart';
import 'package:notes_app/data/repositories/notes_repository.dart';

NotesRepository getNotesRepository() {
  const baseUrl = String.fromEnvironment(
    'NOTES_API',
    defaultValue: 'http://127.0.0.1:8000',
  );
  return NotesRepository(ApiClient(baseUrl));
}
