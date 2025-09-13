// lib/widgets/notes_filter_bar.dart
import 'package:flutter/material.dart';
import 'package:notes_app/features/notes/cubit/notes_state.dart';

class NotesFilterBar extends StatelessWidget {
  final FilterScope scope;
  final bool pinnedOnly;
  final ValueChanged<FilterScope> onScopeChanged;
  final ValueChanged<bool> onPinnedOnlyChanged;

  const NotesFilterBar({
    super.key,
    required this.scope,
    required this.pinnedOnly,
    required this.onScopeChanged,
    required this.onPinnedOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Title'),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            selected: scope == FilterScope.title,
            onSelected: (_) => onScopeChanged(FilterScope.title),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Content'),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            selected: scope == FilterScope.content,
            onSelected: (_) => onScopeChanged(FilterScope.content),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Both'),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            selected: scope == FilterScope.both,
            onSelected: (_) => onScopeChanged(FilterScope.both),
          ),
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('Pinned only'),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            selected: pinnedOnly,
            onSelected: onPinnedOnlyChanged,
          ),
        ],
      ),
    );
  }
}
