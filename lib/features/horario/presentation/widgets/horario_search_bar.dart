import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/horario_provider.dart';

class HorarioSearchBar extends ConsumerStatefulWidget {
  final ValueChanged<String> onChanged;

  const HorarioSearchBar({required this.onChanged, super.key});

  @override
  ConsumerState<HorarioSearchBar> createState() => _HorarioSearchBarState();
}

class _HorarioSearchBarState extends ConsumerState<HorarioSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = _controller.text;
    final esMisRamos = search.trim() == ':';

      return TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Buscar ramo, profesor, sala... (: = mis ramos)',
          prefixIcon: Icon(
            esMisRamos ? Icons.bookmark : Icons.search,
            size: 20,
          ),
          suffixIcon: search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                )
              : null,
          isDense: true,
        ),
        onChanged: (value) {
        widget.onChanged(value);
        setState(() {}); // actualiza ícono y suffixIcon
        },
      );
 }
}