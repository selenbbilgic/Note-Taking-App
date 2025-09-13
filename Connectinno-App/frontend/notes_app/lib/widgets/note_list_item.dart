import 'package:flutter/material.dart';
import 'package:notes_app/data/models/note.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTogglePin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteListItem({
    super.key, // keep outer key passed from parent
    required this.note,
    required this.onTogglePin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // 🔴 REMOVE this inner key to avoid double-key issues
      // key: ValueKey(note.id),
      title: Row(
        children: [
          IconButton(
            icon: Icon(
              note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: note.pinned ? Colors.orange : Colors.grey,
            ),
            onPressed: onTogglePin,
            tooltip: note.pinned ? 'Unpin' : 'Pin',
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(note.title)),
        ],
      ),
      subtitle: Text(note.content),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
        ],
      ),
      onTap: onEdit,
    );
  }
}
