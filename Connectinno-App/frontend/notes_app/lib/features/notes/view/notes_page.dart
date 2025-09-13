import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_app/data/models/note.dart';
import 'package:notes_app/features/notes/cubit/notes_cubit.dart';
import 'package:notes_app/features/notes/cubit/notes_state.dart';
import 'package:notes_app/widgets/note_list_item.dart';
import 'package:notes_app/widgets/notes_filter_bar.dart';
import 'package:notes_app/widgets/notes_search_field.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  bool _filtersOpen = false;

  Future<void> _create(BuildContext context) async {
    final titleCtl = TextEditingController();
    final contentCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('New note'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: contentCtl,
                  decoration: const InputDecoration(labelText: 'Content'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Create'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await context.read<NotesCubit>().create(titleCtl.text, contentCtl.text);
    }
  }

  Future<void> _edit(BuildContext context, Note n) async {
    final titleCtl = TextEditingController(text: n.title);
    final contentCtl = TextEditingController(text: n.content);
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Update note'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: contentCtl,
                  decoration: const InputDecoration(labelText: 'Content'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await context.read<NotesCubit>().update(
        n.id,
        title: titleCtl.text,
        content: contentCtl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notes (${user?.email ?? ''})'),
        actions: [
          IconButton(
            onPressed: () => context.read<NotesCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final notesCubit = context.read<NotesCubit>();
              // finalize any pending deletes *before* token becomes null
              await notesCubit.flushPendingDeletes(); // implement below
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _create(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          if (state is NotesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotesError) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                height: MediaQuery.of(context).size.height * 0.12,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.read<NotesCubit>().load(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            );
          }
          final notes = (state as NotesLoaded).notes;
          final loaded = state;

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    // ⬅️ flex the search field
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        8,
                        8,
                      ), // was ...16, 8
                      child: NotesSearchField(
                        initialQuery: loaded.query,
                        onChanged:
                            (q) => context.read<NotesCubit>().setQuery(q),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _filtersOpen ? 'Hide filters' : 'Show filters',
                    icon: Icon(
                      _filtersOpen ? Icons.filter_alt_off : Icons.filter_alt,
                    ),
                    onPressed:
                        () => setState(() => _filtersOpen = !_filtersOpen),
                  ),
                  const SizedBox(width: 8), // tiny breathing room at end
                ],
              ),
              AnimatedCrossFade(
                crossFadeState:
                    _filtersOpen
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: NotesFilterBar(
                    scope: loaded.scope,
                    pinnedOnly: loaded.pinnedOnly,
                    onScopeChanged:
                        (s) => context.read<NotesCubit>().setScope(s),
                    onPinnedOnlyChanged:
                        (v) => context.read<NotesCubit>().setPinnedOnly(v),
                  ),
                ),
                // When hidden, render a zero-height box so layout is stable
                secondChild: const SizedBox.shrink(),
              ),

              Expanded(
                child:
                    loaded.notes.isEmpty
                        ? const Center(child: Text('No notes'))
                        : ListView.builder(
                          itemCount: notes.length,
                          itemBuilder: (_, i) {
                            final n = notes[i];
                            return NoteListItem(
                              key: ValueKey(n.id),
                              note: n,
                              onTogglePin:
                                  () => context.read<NotesCubit>().togglePin(n),
                              onEdit: () => _edit(context, n),
                              onDelete: () async {
                                final notesCubit = context.read<NotesCubit>();
                                final messenger = ScaffoldMessenger.of(context);

                                await notesCubit.softDelete(n);

                                final ctrl = messenger.showSnackBar(
                                  SnackBar(
                                    content: const Text('Note deleted'),
                                    duration: const Duration(seconds: 4),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      onPressed: () => notesCubit.undoDelete(n),
                                    ),
                                  ),
                                );

                                final reason = await ctrl.closed;
                                if (reason != SnackBarClosedReason.action) {
                                  await notesCubit.confirmDelete(n.id);
                                }
                              },
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
