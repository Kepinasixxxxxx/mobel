import 'package:flutter/material.dart';
import 'tap_scale.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

Future<DateTimeRange?> showCustomDateRangePicker(BuildContext context, {required DateTime initialStart, required DateTime initialEnd}) {
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DateRangePickerSheet(initialStart: initialStart, initialEnd: initialEnd),
  );
}

class _DateRangePickerSheet extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;
  const _DateRangePickerSheet({required this.initialStart, required this.initialEnd});

  @override
  State<_DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<_DateRangePickerSheet> {
  late DateTime _viewedMonth;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    _viewedMonth = DateTime(widget.initialEnd.year, widget.initialEnd.month);
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _end = _start;
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  void _applyPreset(DateTime start, DateTime end) {
    setState(() {
      _start = start;
      _end = end;
      _viewedMonth = DateTime(end.year, end.month);
    });
  }

  bool _isInRange(DateTime day) {
    if (_start == null || _end == null) return false;
    return !day.isBefore(_start!) && !day.isAfter(_end!);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(_viewedMonth.year, _viewedMonth.month, 1);
    final daysInMonth = DateTime(_viewedMonth.year, _viewedMonth.month + 1, 0).day;
    final leadingBlanks = (firstDayOfMonth.weekday - 1) % 7;
    final years = List.generate(now.year - 1999, (i) => now.year - i);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              Row(children: [
                const Text('Pilih Rentang Tanggal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  _start == null ? 'Pilih tanggal mulai' : (_end == null ? '${Formatters.date(_start!)} - pilih tanggal akhir' : '${Formatters.date(_start!)}  -  ${Formatters.date(_end!)}'),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _PresetChip(label: 'Hari Ini', onTap: () => _applyPreset(DateTime(now.year, now.month, now.day), DateTime(now.year, now.month, now.day))),
                    const SizedBox(width: 8),
                    _PresetChip(label: '7 Hari Terakhir', onTap: () => _applyPreset(now.subtract(const Duration(days: 6)), now)),
                    const SizedBox(width: 8),
                    _PresetChip(label: 'Bulan Ini', onTap: () => _applyPreset(DateTime(now.year, now.month, 1), now)),
                    const SizedBox(width: 8),
                    _PresetChip(label: 'Bulan Lalu', onTap: () => _applyPreset(DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 0))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _Dropdown<int>(
                    value: _viewedMonth.month,
                    items: List.generate(12, (i) => i + 1),
                    labelBuilder: (m) => Formatters.monthYear(DateTime(_viewedMonth.year, m)).split(' ').first,
                    onChanged: (m) => setState(() => _viewedMonth = DateTime(_viewedMonth.year, m!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Dropdown<int>(
                    value: _viewedMonth.year,
                    items: years,
                    labelBuilder: (y) => '$y',
                    onChanged: (y) => setState(() => _viewedMonth = DateTime(y!, _viewedMonth.month)),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(
                children: const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                    .map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)))))
                    .toList(),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                itemCount: leadingBlanks + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) return const SizedBox.shrink();
                  final day = DateTime(_viewedMonth.year, _viewedMonth.month, index - leadingBlanks + 1);
                  final isStart = _start != null && day.year == _start!.year && day.month == _start!.month && day.day == _start!.day;
                  final isEnd = _end != null && day.year == _end!.year && day.month == _end!.month && day.day == _end!.day;
                  final inRange = _isInRange(day);
                  return TapScale(
                    onTap: () => _onDayTap(day),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isStart || isEnd ? AppColors.primary : (inRange ? AppColors.primary.withValues(alpha: 0.16) : null),
                        shape: isStart || isEnd ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius: isStart || isEnd ? null : BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('${day.day}', style: TextStyle(fontSize: 12.5, color: isStart || isEnd ? AppColors.onPrimary : AppColors.textPrimary, fontWeight: isStart || isEnd ? FontWeight.w700 : FontWeight.w400)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_start != null && _end != null) ? () => Navigator.pop(context, DateTimeRange(start: _start!, end: _end!)) : null,
                    child: const Text('Terapkan'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
        child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const _Dropdown({required this.value, required this.items, required this.labelBuilder, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(labelBuilder(e), style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
