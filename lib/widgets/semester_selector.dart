import 'package:flutter/material.dart';
import '../models/semester.dart';
import '../services/semester_service.dart';

class SemesterSelector extends StatefulWidget {
  final Semester current;
  final ValueChanged<Semester> onSemesterChanged;

  const SemesterSelector({
    super.key,
    required this.current,
    required this.onSemesterChanged,
  });

  @override
  State<SemesterSelector> createState() => _SemesterSelectorState();
}

class _SemesterSelectorState extends State<SemesterSelector> {
  final _service = SemesterService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Semester>>(
      future: _service.getAll(),
      builder: (context, snapshot) {
        final semesters = snapshot.data ?? [widget.current];
        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.current.id,
            isDense: true,
            items: semesters.map((s) {
              return DropdownMenuItem(value: s.id, child: Text(s.name));
            }).toList(),
            onChanged: (id) {
              if (id == null) return;
              final selected = semesters.firstWhere((s) => s.id == id);
              widget.onSemesterChanged(selected);
            },
          ),
        );
      },
    );
  }
}
