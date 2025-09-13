import 'dart:async';
import 'package:flutter/material.dart';

class NotesSearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  final String? initialQuery;

  const NotesSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Search notes…',
    this.initialQuery,
  });

  @override
  State<NotesSearchField> createState() => _NotesSearchFieldState();
}

class _NotesSearchFieldState extends State<NotesSearchField> {
  late final TextEditingController _ctl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      widget.onChanged(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctl,
      onChanged: _onTextChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }
}
