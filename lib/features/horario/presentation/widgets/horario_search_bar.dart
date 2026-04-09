import 'package:flutter/material.dart';

class HorarioSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const HorarioSearchBar({required this.onChanged, super.key});

  @override
  State<HorarioSearchBar> createState() => _HorarioSearchBarState();
}

class _HorarioSearchBarState extends State<HorarioSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar curso, profesor, sala...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
        isDense: true,
      ),
    );
  }
}
