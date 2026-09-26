import 'package:flutter/material.dart';
import '../common/tap_scale.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../state/rental_provider.dart';
import '../common/status_badge.dart';

class RentalCalendarTab extends StatefulWidget {
  const RentalCalendarTab({super.key});

  @override
  State<RentalCalendarTab> createState() => _RentalCalendarTabState();
}

class _RentalCalendarTabState extends State<RentalCalendarTab> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  Map<DateTime, List<String>> _eventTypesByDay(List<Order> orders) {
    final map = <DateTime, List<String>>{};
    for (final o in orders) {
      final pickup = DateTime(o.rental!.pickupDate.year, o.rental!.pickupDate.month, o.rental!.pickupDate.day);
      final ret = DateTime(o.rental!.returnDate.year, o.rental!.returnDate.month, o.rental!.returnDate.day);
      map.putIfAbsent(pickup, () => []).add('ambil');
      map.putIfAbsent(ret, () => []).add('kembali');
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalProvider>();
    final events = _eventTypesByDay(provider.rentalOrders);
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingBlanks = (firstDayOfMonth.weekday - 1) % 7;

    final agenda = provider.rentalOrders.where((o) {
      final pickup = DateTime(o.rental!.pickupDate.year, o.rental!.pickupDate.month, o.rental!.pickupDate.day);
      final ret = DateTime(o.rental!.returnDate.year, o.rental!.returnDate.month, o.rental!.returnDate.day);
      return pickup == _selectedDay || ret == _selectedDay;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(
            children: [
              Row(children: [
                Text(Formatters.monthYear(_focusedMonth), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1))),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1))),
              ]),
              Row(
                children: const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                    .map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)))))
                    .toList(),
              ),
              const SizedBox(height: 4),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                itemCount: leadingBlanks + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) return const SizedBox.shrink();
                  final day = DateTime(_focusedMonth.year, _focusedMonth.month, index - leadingBlanks + 1);
                  final dayEvents = events[day] ?? [];
                  final selected = day == _selectedDay;
                  return TapScale(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: selected ? AppColors.primary : null, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${day.day}', style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
                          if (dayEvents.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: dayEvents.toSet().map((t) => Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      decoration: BoxDecoration(color: t == 'ambil' ? AppColors.info : AppColors.success, shape: BoxShape.circle),
                                    )).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Row(children: [
                _LegendDot(color: AppColors.info, label: 'Pengambilan'),
                SizedBox(width: 14),
                _LegendDot(color: AppColors.success, label: 'Pengembalian'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Agenda ${Formatters.date(_selectedDay)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (agenda.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Tidak ada jadwal pada tanggal ini.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)))
        else
          ...agenda.map((o) {
            final pickup = DateTime(o.rental!.pickupDate.year, o.rental!.pickupDate.month, o.rental!.pickupDate.day);
            final isAmbil = pickup == _selectedDay;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: isAmbil ? AppColors.info : AppColors.success, width: 4)),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        TagChip(label: isAmbil ? 'AMBIL' : 'KEMBALI', color: isAmbil ? AppColors.info : AppColors.success, background: isAmbil ? AppColors.infoBg : AppColors.successBg),
                        const SizedBox(width: 6),
                        Text(o.customer.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ]),
                      const SizedBox(height: 3),
                      Text(o.items.isNotEmpty ? o.items.first.name : '#${o.orderNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                RentalStatusBadge(status: o.rental!.status),
              ]),
            );
          }),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}
