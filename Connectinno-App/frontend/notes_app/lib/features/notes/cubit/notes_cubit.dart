// lib/features/notes/cubit/notes_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:notes_app/data/models/note.dart';
import 'package:notes_app/data/repositories/notes_repository.dart';
import 'notes_state.dart';

class NotesCubit extends Cubit<NotesState> {
  final NotesRepository repo;

  NotesCubit(this.repo) : super(const NotesLoading());

  // Source of truth (full list from backend)
  List<Note> _all = [];

  // Filter state
  String _query = '';
  FilterScope _scope = FilterScope.both;
  bool _pinnedOnly = false;

  // ---- Filtering helpers ----
  List<Note> _applyFilter() {
    Iterable<Note> items = _all;

    // 1) Pinned filter always applies
    if (_pinnedOnly) {
      items = items.where((n) => n.pinned);
    }

    final q = _query.trim().toLowerCase();

    // 2) If query is empty, still apply scope as a coarse filter
    if (q.isEmpty) {
      switch (_scope) {
        case FilterScope.title:
          items = items.where((n) => n.title.trim().isNotEmpty);
          break;
        case FilterScope.content:
          items = items.where((n) => n.content.trim().isNotEmpty);
          break;
        case FilterScope.both:
          // no extra filtering
          break;
      }
      return List<Note>.from(items);
    }

    // 3) Query present: scope acts as search scope
    bool match(Note n) {
      final inTitle = n.title.toLowerCase().contains(q);
      final inContent = n.content.toLowerCase().contains(q);
      switch (_scope) {
        case FilterScope.title:
          return inTitle;
        case FilterScope.content:
          return inContent;
        case FilterScope.both:
          return inTitle || inContent;
      }
    }

    return items.where(match).toList();
  }

  void setQuery(String q) {
    _query = q;
    emit(
      NotesLoaded(
        _applyFilter(),
        query: _query,
        scope: _scope,
        pinnedOnly: _pinnedOnly,
      ),
    );
  }

  void setScope(FilterScope scope) {
    _scope = scope;
    emit(
      NotesLoaded(
        _applyFilter(),
        query: _query,
        scope: _scope,
        pinnedOnly: _pinnedOnly,
      ),
    );
  }

  void setPinnedOnly(bool v) {
    _pinnedOnly = v;
    emit(
      NotesLoaded(
        _applyFilter(),
        query: _query,
        scope: _scope,
        pinnedOnly: _pinnedOnly,
      ),
    );
  }

  // ---- Loading / refreshing ----
  Future<void> load() async {
    emit(const NotesLoading());
    try {
      final fetched = await repo.fetchNotes(); // already pinned-first/newest
      // de-dup (belt & suspenders)
      final seen = <String>{};
      _all = [];
      for (final n in fetched) {
        if (seen.add(n.id)) _all.add(n);
      }
      emit(
        NotesLoaded(
          _applyFilter(),
          query: _query,
          scope: _scope,
          pinnedOnly: _pinnedOnly,
        ),
      );
    } catch (_) {
      emit(const NotesError('There is a connection error: Please try again!'));
    }
  }

  Future<void> _refreshSilently() async {
    try {
      final fetched = await repo.fetchNotes();
      final seen = <String>{};
      _all = [];
      for (final n in fetched) {
        if (seen.add(n.id)) _all.add(n);
      }
      emit(
        NotesLoaded(
          _applyFilter(),
          query: _query,
          scope: _scope,
          pinnedOnly: _pinnedOnly,
        ),
      );
    } catch (_) {
      // Keep UI as-is if silent refresh fails
    }
  }

  // ---- CRUD (keep your existing ones; key shown methods below) ----

  Future<void> togglePin(Note note) async {
    final cur = state;

    // Optimistic: update _all (filters operate on _all)
    final idxAll = _all.indexWhere((n) => n.id == note.id);
    if (idxAll != -1) {
      _all[idxAll] = _all[idxAll].copyWith(pinned: !note.pinned);
    }

    // Optimistic: update visible list
    if (cur is NotesLoaded) {
      final list =
          cur.notes
              .map(
                (n) => n.id == note.id ? n.copyWith(pinned: !note.pinned) : n,
              )
              .toList();
      emit(
        NotesLoaded(
          list,
          query: cur.query,
          scope: cur.scope,
          pinnedOnly: cur.pinnedOnly,
        ),
      );
    }

    try {
      await repo.update(note.id, pinned: !note.pinned);
    } catch (_) {
      // rollback
      if (idxAll != -1) {
        _all[idxAll] = _all[idxAll].copyWith(pinned: note.pinned);
      }
      if (cur is NotesLoaded) emit(cur);
      return;
    }

    await _refreshSilently(); // server-sorted order, no spinner
  }

  Future<void> create(String title, String content) async {
    final prev = state;
    try {
      final created = await repo.create(title, content);
      _all.insert(0, created);
      emit(
        NotesLoaded(
          _applyFilter(),
          query: _query,
          scope: _scope,
          pinnedOnly: _pinnedOnly,
        ),
      );
    } catch (_) {
      emit(const NotesError('Failed to create note.'));
      if (prev is NotesLoaded) emit(prev);
    }
  }

  Future<void> update(String id, {String? title, String? content}) async {
    final prev = state;
    try {
      final updated = await repo.update(id, title: title, content: content);
      _all = _all.map((n) => n.id == id ? updated : n).toList();
      emit(
        NotesLoaded(
          _applyFilter(),
          query: _query,
          scope: _scope,
          pinnedOnly: _pinnedOnly,
        ),
      );
    } catch (_) {
      emit(const NotesError('Failed to update note.'));
      if (prev is NotesLoaded) emit(prev);
    }
  }

  // Undo-able delete you already wired:
  final Map<String, Note> _pendingDeletes = {};
  Future<void> softDelete(Note note) async {
    _pendingDeletes[note.id] = note;
    _all = _all.where((n) => n.id != note.id).toList();
    emit(
      NotesLoaded(
        _applyFilter(),
        query: _query,
        scope: _scope,
        pinnedOnly: _pinnedOnly,
      ),
    );
  }

  void undoDelete(Note note) {
    if (_pendingDeletes.remove(note.id) != null) {
      _all.insert(0, note);
      emit(
        NotesLoaded(
          _applyFilter(),
          query: _query,
          scope: _scope,
          pinnedOnly: _pinnedOnly,
        ),
      );
    }
  }

  Future<void> confirmDelete(String id) async {
    final pending = _pendingDeletes.remove(id);
    if (pending == null) return;
    try {
      await repo.delete(id);
    } catch (_) {
      await load();
    }
  }

  Future<void> flushPendingDeletes() async {
    for (final id in List<String>.from(_pendingDeletes.keys)) {
      try {
        await repo.delete(id);
      } catch (_) {}
      _pendingDeletes.remove(id);
    }
  }
}
