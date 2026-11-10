import 'dart:async';
import 'package:flutter/material.dart';

class ListSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const ListSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });
  @override
  State<ListSearchField> createState() => _ListSearchFieldState();
}

class _ListSearchFieldState extends State<ListSearchField> {
  final _text = TextEditingController();
  Timer? _timer;
  void _change(String value, {bool immediately = false}) {
    _timer?.cancel();
    setState(() {});
    if (immediately) {
      widget.onChanged(value.trim());
    } else {
      _timer = Timer(
        const Duration(milliseconds: 450),
        () => widget.onChanged(value.trim()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: TextField(
      controller: _text,
      onChanged: _change,
      onSubmitted: (value) => _change(value, immediately: true),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _text.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa tìm kiếm',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _text.clear();
                  _change('', immediately: true);
                },
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
