// lib/data/local/outbox_ds.dart
import 'package:hive/hive.dart';

enum OutboxOp { create, update, delete }

class OutboxDs {
  final Box box;
  OutboxDs(this.box);

  Future<void> enqueue(OutboxOp op, Map<String, dynamic> payload) async {
    await box.add({
      'op': op.name,
      'payload': payload,
      'ts': DateTime.now().toIso8601String(),
    });
  }

  /// Returns entries as key -> map (op/payload/ts)
  Map<dynamic, Map<String, dynamic>> entries() {
    return box.toMap().map(
      (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
    );
  }

  Future<void> removeAtKey(dynamic key) async => box.delete(key);
}
