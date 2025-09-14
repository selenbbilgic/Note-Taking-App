import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    // Check connectivity every 10 seconds
    _startConnectivityTimer();
  }

  void _startConnectivityTimer() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _checkConnectivity();
        _startConnectivityTimer(); // Schedule next check
      }
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final isOnline = result.any(
        (connectivity) =>
            connectivity == ConnectivityResult.mobile ||
            connectivity == ConnectivityResult.wifi ||
            connectivity == ConnectivityResult.ethernet,
      );
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    } catch (e) {
      // If connectivity check fails, assume online
      if (mounted) {
        setState(() {
          _isOnline = true;
        });
      }
    }
  }

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
      try {
        await context.read<NotesCubit>().create(titleCtl.text, contentCtl.text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create note: ${e.toString()}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _create(context),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _togglePin(BuildContext context, Note n) async {
    try {
      await context.read<NotesCubit>().togglePin(n);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(n.pinned ? 'Note unpinned' : 'Note pinned'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on OfflinePinException catch (e) {
      if (context.mounted) {
        _showOfflinePinDialog(context, e.message);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${n.pinned ? 'unpin' : 'pin'} note: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _togglePin(context, n),
            ),
          ),
        );
      }
    }
  }

  void _showOfflinePinDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange.shade600, size: 28),
              const SizedBox(width: 12),
              const Text('Offline Mode'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              const Text(
                'To pin or unpin notes, you need to be connected to the internet. Please check your connection and try again.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Check connectivity and refresh data
                _checkConnectivity();
                context.read<NotesCubit>().load();
              },
              child: const Text('Check Connection'),
            ),
          ],
        );
      },
    );
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
      try {
        await context.read<NotesCubit>().update(
          n.id,
          title: titleCtl.text,
          content: contentCtl.text,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update note: ${e.toString()}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _edit(context, n),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Text('Notes (${user?.email ?? ''})')]),
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
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.red.shade50,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.read<NotesCubit>().load(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Show more details or contact support
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error details: ${state.message}',
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text('More Info'),
                        ),
                      ],
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
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No notes found'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed:
                                    () => context.read<NotesCubit>().load(),
                                child: const Text('Refresh'),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Query: "${loaded.query}" | Scope: ${loaded.scope} | Pinned only: ${loaded.pinnedOnly}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'User: ${user?.email ?? 'Unknown'} | UID: ${user?.uid ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: notes.length,
                          itemBuilder: (_, i) {
                            final n = notes[i];
                            return NoteListItem(
                              key: ValueKey(n.id),
                              note: n,
                              onTogglePin: () => _togglePin(context, n),
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
