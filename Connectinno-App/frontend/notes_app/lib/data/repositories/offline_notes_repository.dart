import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:notes_app/data/api_client.dart';
import 'package:notes_app/data/models/note.dart';
import 'package:notes_app/data/repositories/notes_repository.dart';
import 'package:notes_app/data/local/local_notes_ds.dart';
import 'package:notes_app/data/local/outbox_ds.dart';

class OfflineNotesRepository implements NotesRepository {
  final NotesRepository remote;
  final LocalNotesDs local;
  final OutboxDs outbox;

  OfflineNotesRepository({
    required this.remote,
    required this.local,
    required this.outbox,
  });

  // ---- add this to satisfy the interface ----
  @override
  ApiClient get api => remote.api; // delegate to your existing remote repo

  Future<bool> _online() async {
    try {
      final result = await Connectivity().checkConnectivity();
      print('[OfflineNotesRepository] Connectivity result: $result');

      // Check if we have any active connection
      final isOnline = result.any(
        (connectivity) =>
            connectivity == ConnectivityResult.mobile ||
            connectivity == ConnectivityResult.wifi ||
            connectivity == ConnectivityResult.ethernet,
      );

      print('[OfflineNotesRepository] Is online: $isOnline');
      return isOnline;
    } catch (e) {
      print('[OfflineNotesRepository] Connectivity check failed: $e');
      // If connectivity check fails, assume we're online and let the API call determine
      return true;
    }
  }

  @override
  Future<List<Note>> fetchNotes() async {
    print('[OfflineNotesRepository] Starting fetchNotes...');
    final cachedMaps = await local.getAll();
    var cached = cachedMaps.map(Note.fromJson).toList();
    final hadCache = cached.isNotEmpty; // <-- remember if we had cache
    print('[OfflineNotesRepository] Found ${cached.length} cached notes');

    // Always try remote first, regardless of connectivity check
    print('[OfflineNotesRepository] Attempting to fetch from remote...');
    try {
      final fresh = await remote.fetchNotes();
      print(
        '[OfflineNotesRepository] Fetched ${fresh.length} notes from remote',
      );
      await local.putAll(fresh.map((n) => n.toJson()).toList());
      cached = fresh;
      await trySync();
    } catch (e) {
      print('[OfflineNotesRepository] Error fetching from remote: $e');
      // IMPORTANT: on first run (no cache), surface the error
      if (!hadCache) {
        if (e.toString().contains('Connection refused')) {
          throw Exception(
            'Unable to connect to the server. Please check your internet connection and try again.',
          );
        } else if (e.toString().contains('Authentication')) {
          throw Exception('Authentication failed. Please sign in again.');
        } else {
          throw Exception('Failed to load notes. Please try again later.');
        }
      }
      // otherwise keep showing cached silently
    }

    print('[OfflineNotesRepository] Returning ${cached.length} notes');
    return cached;
  }

  // ---- add {bool pinned = false} to match interface ----
  @override
  Future<Note> create(
    String title,
    String content, {
    bool pinned = false,
  }) async {
    final temp = Note.temp(
      title: title,
      content: content,
    ).copyWith(pinned: pinned);
    await local.upsert(temp.toJson());

    // Always try remote create first, regardless of connectivity check
    try {
      final created = await remote.create(title, content, pinned: pinned);
      await local.delete(temp.id);
      await local.upsert(created.toJson());
      await trySync();
      return created;
    } catch (e) {
      print('[OfflineNotesRepository] Remote create failed: $e');
      // Fallback to offline mode
      await outbox.enqueue(OutboxOp.create, {
        'title': title,
        'content': content,
        'pinned': pinned,
        'client_id': temp.id,
      });
      return temp;
    }
  }

  @override
  Future<Note> update(
    String id, {
    String? title,
    String? content,
    bool? pinned,
  }) async {
    print('[OfflineNotesRepository] Updating note $id with pinned: $pinned');
    final cached = await local.getAll();
    final idx = cached.indexWhere((m) => m['id'] == id);
    if (idx != -1) {
      final m = Map<String, dynamic>.from(cached[idx]);
      if (title != null) m['title'] = title;
      if (content != null) m['content'] = content;
      if (pinned != null) m['pinned'] = pinned;
      m['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await local.upsert(m);
    }

    // Always try remote update first, regardless of connectivity check
    print('[OfflineNotesRepository] Attempting remote update for note $id');
    try {
      print('[OfflineNotesRepository] Calling remote update for note $id');
      final updated = await remote.update(
        id,
        title: title,
        content: content,
        pinned: pinned,
      );
      print('[OfflineNotesRepository] Remote update successful for note $id');
      await local.upsert(updated.toJson());
      await trySync();
      return updated;
    } catch (e) {
      print('[OfflineNotesRepository] Remote update failed for note $id: $e');
      // Fallback to offline mode
      await outbox.enqueue(OutboxOp.update, {
        'id': id,
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (pinned != null) 'pinned': pinned,
      });
      final map =
          idx != -1
              ? cached[idx]
              : {
                'id': id,
                'title': title ?? '',
                'content': content ?? '',
                'pinned': pinned ?? false,
                'created_at': DateTime.now().toUtc().toIso8601String(),
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              };
      return Note.fromJson(Map<String, dynamic>.from(map));
    }
  }

  @override
  Future<void> delete(String id) async {
    await local.delete(id);
    // Always try remote delete first, regardless of connectivity check
    try {
      await remote.delete(id);
      await trySync();
    } catch (e) {
      print('[OfflineNotesRepository] Remote delete failed for note $id: $e');
      // Fallback to offline mode
      await outbox.enqueue(OutboxOp.delete, {'id': id});
    }
  }

  Future<void> trySync() async {
    if (!await _online()) return;

    // iterate over the Map’s entries and convert to a list
    for (final entry in outbox.entries().entries.toList()) {
      final key = entry.key;
      final val = entry.value;
      final op = val['op'] as String;
      final payload = Map<String, dynamic>.from(val['payload'] as Map);

      try {
        switch (op) {
          case 'create':
            final created = await remote.create(
              payload['title'] as String,
              payload['content'] as String,
              pinned: (payload['pinned'] as bool?) ?? false,
            );
            final clientId = payload['client_id'];
            if (clientId != null) await local.delete(clientId as String);
            await local.upsert(created.toJson());
            break;

          case 'update':
            final id = payload['id'] as String;
            final updated = await remote.update(
              id,
              title: payload['title'] as String?,
              content: payload['content'] as String?,
              pinned: payload['pinned'] as bool?,
            );
            await local.upsert(updated.toJson());
            break;

          case 'delete':
            final id = payload['id'] as String;
            await remote.delete(id);
            await local.delete(id);
            break;
        }
        await outbox.removeAtKey(key);
      } catch (_) {
        break; // stop on first failure; retry later
      }
    }
  }
}
