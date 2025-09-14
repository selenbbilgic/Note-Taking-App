// lib/data/local/local_notes_ds.dart
import 'package:hive/hive.dart';

class LocalNotesDs {
  final Box box;
  LocalNotesDs(this.box);

  Future<List<Map<String, dynamic>>> getAll() async {
    return box.values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  Future<void> putAll(List<Map<String, dynamic>> notes) async {
    final entries = {for (final m in notes) (m['id'] as String): m};
    await box.putAll(entries);
  }

  Future<void> upsert(Map<String, dynamic> note) async {
    final id = note['id'] as String;
    await box.put(id, note);
  }

  Future<void> delete(String id) => box.delete(id);

  Future<void> clear() => box.clear();
}
