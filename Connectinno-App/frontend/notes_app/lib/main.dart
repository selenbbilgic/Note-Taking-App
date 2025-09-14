import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notes_app/data/api_client.dart';
import 'package:notes_app/data/local/local_notes_ds.dart';
import 'package:notes_app/data/local/outbox_ds.dart';
import 'package:notes_app/data/repositories/offline_notes_repository.dart';
import 'package:notes_app/data/repositories/remote_notes_repository.dart';
import 'package:notes_app/features/auth/cubit/auth_cubit.dart';
import 'package:notes_app/features/auth/cubit/auth_state.dart';
import 'package:notes_app/features/auth/view/login_page.dart';
import 'package:notes_app/features/notes/cubit/notes_cubit.dart';
import 'package:notes_app/features/notes/view/notes_page.dart';
import 'package:notes_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Hive init
  await Hive.initFlutter();
  //await Hive.openBox<Map>('notes');
  //await Hive.openBox<Map>('outbox');

  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(FirebaseAuth.instance),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Notes',
        theme: appTheme(),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            print('[Main] Auth state: $state');
            if (state is Authenticated) {
              final uid = state.user.uid;
              print('[Main] User authenticated: $uid');

              return FutureBuilder<OfflineNotesRepository>(
                future: _buildOfflineRepo(uid),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError || snap.data == null) {
                    return const Scaffold(
                      body: Center(child: Text('Failed to init cache')),
                    );
                  }

                  final repo = snap.data!;
                  return RepositoryProvider.value(
                    value: repo,
                    child: BlocProvider(
                      create:
                          (_) =>
                              NotesCubit(repo)
                                ..load(), // uses cache when offline
                      child: NotesPage(key: ValueKey(uid)),
                    ),
                  );
                },
              );
            }
            // Unauthenticated / Unknown / AuthError -> show Login
            return const LoginPage();
          },
        ),
      ),
    );
  }
}

Future<OfflineNotesRepository> _buildOfflineRepo(String uid) async {
  // Open (or create) per-user boxes
  final notesBox = await Hive.openBox('notes_$uid');
  final outboxBox = await Hive.openBox('outbox_$uid');

  // ---- ONE-TIME MIGRATION FROM OLD GLOBAL BOXES ----
  if (Hive.isBoxOpen('notes')) {
    final old = Hive.box('notes');
    if (notesBox.isEmpty && old.isNotEmpty) {
      // copy all
      await notesBox.putAll(old.toMap());
      await old.clear(); // or await Hive.deleteBoxFromDisk('notes');
    }
  }
  if (Hive.isBoxOpen('outbox')) {
    final old = Hive.box('outbox');
    if (outboxBox.isEmpty && old.isNotEmpty) {
      await outboxBox.putAll(old.toMap());
      await old.clear(); // or delete
    }
  }
  // If old boxes aren’t open, but might exist on disk:
  if (!Hive.isBoxOpen('notes') && await Hive.boxExists('notes')) {
    final old = await Hive.openBox('notes');
    if (notesBox.isEmpty && old.isNotEmpty) {
      await notesBox.putAll(old.toMap());
    }
    await old.deleteFromDisk();
  }
  if (!Hive.isBoxOpen('outbox') && await Hive.boxExists('outbox')) {
    final old = await Hive.openBox('outbox');
    if (outboxBox.isEmpty && old.isNotEmpty) {
      await outboxBox.putAll(old.toMap());
    }
    await old.deleteFromDisk();
  }
  // -----------------------------------------------

  // iOS simulator: use localhost
  const baseUrl = String.fromEnvironment(
    'NOTES_API',
    defaultValue: 'http://localhost:8000',
  );
  final api = ApiClient(baseUrl);
  final remote = RemoteNotesRepository(api);

  return OfflineNotesRepository(
    remote: remote,
    local: LocalNotesDs(notesBox),
    outbox: OutboxDs(outboxBox),
  );
}

ThemeData appTheme() {
  const accent = Color.fromARGB(255, 198, 229, 235); // your blue-ish

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: accent),
    scaffoldBackgroundColor: Colors.white,

    appBarTheme: const AppBarTheme(
      backgroundColor: accent,
      foregroundColor: Colors.black,
      elevation: 0,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.black,
    ),

    // 👇 This controls TextField borders globally
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black87),
      floatingLabelStyle: const TextStyle(color: Colors.black87),
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.black, // caret color
      selectionColor: Color(0x33666666),
      selectionHandleColor: Colors.black,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[800],
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
