import 'package:flutter/material.dart';

// FR-REPORT-01/03, BR-25: date-only API parameters represent Vietnam calendar days.
class ReportPeriod extends StatefulWidget {
  const ReportPeriod({super.key, required this.onChanged});
  final ValueChanged<Map<String, Object?>> onChanged;

  @override
  State<ReportPeriod> createState() => _ReportPeriodState();
}

class _ReportPeriodState extends State<ReportPeriod> {
  DateTimeRange? _range;

  String day(DateTime value) => value.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      OutlinedButton.icon(
        icon: const Icon(Icons.date_range_outlined),
        label: Text(
          _range == null
              ? 'Tất cả thời gian'
              : '${day(_range!.start)} → ${day(_range!.end)}',
        ),
        onPressed: () async {
          final now = DateTime.now().toUtc().add(const Duration(hours: 7));
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(now.year, now.month, now.day),
            initialDateRange: _range,
          );
          if (range == null || !mounted) return;
          setState(() => _range = range);
          widget.onChanged({'from': day(range.start), 'to': day(range.end)});
        },
      ),
      if (_range != null)
        TextButton(
          onPressed: () {
            setState(() => _range = null);
            widget.onChanged({});
          },
          child: const Text('Xóa lọc'),
        ),
    ],
  );
}
