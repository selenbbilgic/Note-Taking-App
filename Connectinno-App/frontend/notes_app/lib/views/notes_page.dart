import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/services/api_client.dart';
import 'package:notes_app/services/note_service.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late final NotesService svc;
  List<Note> notes = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    const baseUrl = String.fromEnvironment(
      'NOTES_API',
      defaultValue: 'http://127.0.0.1:8000',
    );
    svc = NotesService(ApiClient(baseUrl));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      notes = await svc.list();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted)
        setState(() {
          loading = false;
        });
    }
  }

  Future<void> _create() async {
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
      await svc.create(titleCtl.text, contentCtl.text);
      await _load();
    }
  }

  Future<void> _edit(Note n) async {
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
      await svc.update(n.id, title: titleCtl.text, content: contentCtl.text);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes (${user?.email ?? ''})'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              )
              : ListView.builder(
                itemCount: notes.length,
                itemBuilder: (_, i) {
                  final n = notes[i];
                  return ListTile(
                    title: Text(n.title),
                    subtitle: Text(n.content),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _edit(n),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await svc.delete(n.id);
                            await _load();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
