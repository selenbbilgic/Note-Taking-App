import 'package:equatable/equatable.dart';
import 'package:notes_app/data/models/note.dart';

enum FilterScope { title, content, both }

sealed class NotesState extends Equatable {
  const NotesState();
  @override
  List<Object?> get props => [];
}

class NotesLoading extends NotesState {
  const NotesLoading();
}

class NotesLoaded extends NotesState {
  final List<Note> notes; // filtered view
  final String query; // current search text
  final FilterScope scope; // title/content/both
  final bool pinnedOnly; // show only pinned

  const NotesLoaded(
    this.notes, {
    this.query = '',
    this.scope = FilterScope.both,
    this.pinnedOnly = false,
  });

  @override
  List<Object?> get props => [notes, query, scope, pinnedOnly];
}

class NotesError extends NotesState {
  final String message;
  const NotesError(this.message);
  @override
  List<Object?> get props => [message];
}
