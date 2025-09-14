/// auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:notes_app/data/api_client.dart';

import 'package:notes_app/data/local/local_notes_ds.dart';
import 'package:notes_app/data/local/outbox_ds.dart';
import 'package:notes_app/data/models/note.dart';
import 'package:notes_app/data/repositories/offline_notes_repository.dart';
import 'package:notes_app/data/repositories/remote_notes_repository.dart';
import 'package:notes_app/features/notes/cubit/notes_cubit.dart';
import 'package:notes_app/features/notes/view/notes_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        final user = snap.data;
        if (user == null) {
          return const _SignInPage();
        }
        return _NotesScope(uid: user.uid);
      },
    );
  }
}

class _NotesScope extends StatefulWidget {
  final String uid;
  const _NotesScope({required this.uid});

  @override
  State<_NotesScope> createState() => _NotesScopeState();
}

class _NotesScopeState extends State<_NotesScope> {
  Box? _notesBox;
  Box? _outboxBox;
  late final ApiClient _api;
  late final Future<void> _initFuture; // <- we’ll await this in build
  OfflineNotesRepository? _repo;

  List<Note> _cachedNotes = const [];

  @override
  void initState() {
    super.initState();
    _api = ApiClient(
      const String.fromEnvironment(
        'NOTES_API',
        defaultValue: 'http://127.0.0.1:8000',
      ),
    );
    print("selen123");
    _initFuture = _open(); // kick off once
  }

  Future<void> _open() async {
    debugPrint('[NotesScope] opening boxes for uid=${widget.uid}');
    _notesBox = await Hive.openBox('notes_${widget.uid}');
    _outboxBox = await Hive.openBox('outbox_${widget.uid}');
    print('[NotesScope] cache count=${_notesBox!.length}');

    // NEW: read cache right here
    final local = LocalNotesDs(_notesBox!);
    final cachedMaps = await local.getAll();
    _cachedNotes = cachedMaps.map(Note.fromJson).toList();

    final remote = RemoteNotesRepository(_api);
    _repo = OfflineNotesRepository(
      remote: remote,
      local: local,
      outbox: OutboxDs(_outboxBox!),
    );
  }

  @override
  void dispose() {
    _notesBox?.close();
    _outboxBox?.close();
    // If you want offline after logout, DO NOT deleteFromDisk here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // If there was an exception opening boxes, show a simple fallback
        if (snap.hasError || _repo == null) {
          return const Scaffold(
            body: Center(child: Text('Failed to init local cache')),
          );
        }

        // Provide repo + cubit AFTER boxes are ready
        return RepositoryProvider.value(
          value: _repo!,
          child: BlocProvider(
            create: (_) {
              final cubit = NotesCubit(_repo!);
              //  show cached notes immediately (even offline)
              if (_cachedNotes.isNotEmpty) {
                cubit.seedFromCache(_cachedNotes);
              }
              // Then try to refresh (will no-op offline)
              cubit.load();
              return cubit;
            },
            child: const NotesPage(),
          ),
        );
      },
    );
  }
}

class _SignInPage extends StatelessWidget {
  const _SignInPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Sign in')));
  }
}
