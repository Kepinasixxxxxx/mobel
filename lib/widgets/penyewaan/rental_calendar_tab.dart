import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/operations_models.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../screens/penyewaan/appointment_form_screen.dart';
import '../../screens/penyewaan/penyewaan_detail_screen.dart';
import '../../state/appointment_provider.dart';
import '../../state/product_provider.dart';
import '../../state/rental_provider.dart';
import '../common/tap_scale.dart';
import '../vg/vg_ui.dart';

const _pickupColor = AppColors.primary;
const _returnColor = Color(0xFF22A447);
const _busyColor = Color(0xFFF59E0B);
const _apptColor = Color(0xFF3553B5);
const _busyThreshold = 3;

class RentalCalendarTab extends StatefulWidget {
  const RentalCalendarTab({super.key});

  @override
  State<RentalCalendarTab> createState() => _RentalCalendarTabState();
}

class _RentalCalendarTabState extends State<RentalCalendarTab> {
  late DateTime _month;
  late DateTime _selected;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = _day(now);
    Future.microtask(_loadMonth);
  }

  Future<void> _loadMonth() async {
    if (!mounted) return;
    await context.read<AppointmentProvider>().fetchRange(DateTime(_month.year, _month.month - 1, 20), DateTime(_month.year, _month.month + 1, 10));
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _loadMonth();
  }

  Future<void> _book() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentFormScreen(initialDate: _selected)));
    _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final rentals = context.watch<RentalProvider>();
    final appointmentProvider = context.watch<AppointmentProvider>();
    final products = context.watch<ProductProvider>();
    final orders = rentals.rentalOrders.where((o) => o.status != OrderStatus.dibatalkan).toList();

    final pickups = <DateTime, int>{};
    final returns = <DateTime, int>{};
    for (final o in orders) {
      pickups.update(_day(o.rental!.pickupDate), (v) => v + 1, ifAbsent: () => 1);
      returns.update(_day(o.rental!.returnDate), (v) => v + 1, ifAbsent: () => 1);
    }

    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = (first.weekday - 1) % 7;
    final cells = ((leading + daysInMonth) / 7).ceil() * 7;

    final agenda = <(Order, bool)>[
      for (final o in orders)
        if (_day(o.rental!.pickupDate) == _selected) (o, true),
      for (final o in orders)
        if (_day(o.rental!.returnDate) == _selected) (o, false),
    ];
    final isToday = _selected == _day(DateTime.now());
    final dayAppointments = appointmentProvider.onDay(_selected);
    final apptCount = <DateTime, int>{};
    for (final a in appointmentProvider.appointments) {
      apptCount.update(_day(a.startAt), (v) => v + 1, ifAbsent: () => 1);
    }

    final totalStock = products.products.fold<int>(0, (s, p) => s + p.totalStockRent);
    final rented = orders
        .where((o) => o.rental!.status == RentalStatus.diambil || o.rental!.status == RentalStatus.terlambat || o.rental!.status == RentalStatus.dipesan)
        .fold<int>(0, (s, o) => s + o.totalQuantity);
    final occupancy = totalStock == 0 ? 0.0 : (rented / totalStock).clamp(0.0, 1.0);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: rentals.fetchRentals,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          VgCard(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(children: [
              Row(children: [
                const VgIconBadge(icon: Icons.calendar_month_outlined, size: 36, circle: true),
                const SizedBox(width: 10),
                Expanded(child: Text(Formatters.monthYear(_month), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                  onPressed: () => _changeMonth(-1),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  onPressed: () => _changeMonth(1),
                ),
              ]),
              const SizedBox(height: 8),
              Row(
                children: const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                    .map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w500)))))
                    .toList(),
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.95),
                itemCount: cells,
                itemBuilder: (context, index) {
                  final date = DateTime(_month.year, _month.month, index - leading + 1);
                  final inMonth = date.month == _month.month;
                  final selected = date == _selected;
                  final p = pickups[date] ?? 0;
                  final r = returns[date] ?? 0;
                  final ap = apptCount[date] ?? 0;
                  final busy = p + r + ap >= _busyThreshold;
                  return TapScale(
                    onTap: () => setState(() {
                      _selected = date;
                      if (!inMonth) _month = DateTime(date.year, date.month);
                    }),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: selected ? AppColors.primary : Colors.transparent, shape: BoxShape.circle),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                            color: selected ? Colors.white : (inMonth ? AppColors.textPrimary : AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (p > 0) const _Dot(color: _pickupColor),
                        if (r > 0) const _Dot(color: _returnColor),
                        if (ap > 0) const _Dot(color: _apptColor),
                        if (busy) const _Dot(color: _busyColor),
                      ]),
                    ]),
                  );
                },
              ),
              const SizedBox(height: 8),
              const VgInset(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                radius: 4,
                child: Wrap(alignment: WrapAlignment.spaceEvenly, spacing: 14, runSpacing: 6, children: [
                  _Legend(color: _pickupColor, label: 'Pengambilan'),
                  _Legend(color: _returnColor, label: 'Pengembalian'),
                  _Legend(color: _apptColor, label: 'Fitting / Konsultasi'),
                  _Legend(color: _busyColor, label: 'Jadwal Padat'),
                ]),
              ),
            ]),
          ),
          VgInset(
            padding: const EdgeInsets.all(12),
            radius: 4,
            child: Row(children: [
              const VgIconBadge(icon: Icons.event_note_outlined, color: Colors.white, background: AppColors.primary, size: 36, circle: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Agenda ${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selected)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  Text('${agenda.length + dayAppointments.length} Aktivitas Terjadwal', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                ]),
              ),
              if (isToday) const VgPill(label: 'Hari Ini', color: AppColors.textPrimary, background: AppColors.surface, fontSize: 11),
            ]),
          ),
          const SizedBox(height: 10),
          if (agenda.isEmpty && dayAppointments.isEmpty)
            const VgCard(child: Text('Tidak ada jadwal pada tanggal ini.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)))
          else ...[
            for (final (order, pickup) in agenda) _AgendaTile(order: order, pickup: pickup),
            for (final a in dayAppointments) _AppointmentTile(appointment: a),
          ],
          VgButton(label: 'Booking Jadwal', icon: Icons.add_rounded, expanded: true, height: 46, onPressed: _book),
          const SizedBox(height: 10),
          const SizedBox(height: 4),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.donut_large_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Okupansi Kostum', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                Text('${(occupancy * 100).round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: occupancy, minHeight: 10, backgroundColor: AppColors.beige, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('$rented terbooking dari $totalStock stel kostum', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                if (occupancy >= 0.75) ...[
                  const _Dot(color: _busyColor),
                  const Text('Okupansi Tinggi', style: TextStyle(fontSize: 12, color: _busyColor)),
                ],
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary)),
    ]);
  }
}

class _AgendaTile extends StatelessWidget {
  final Order order;
  final bool pickup;
  const _AgendaTile({required this.order, required this.pickup});

  @override
  Widget build(BuildContext context) {
    final rental = order.rental!;
    final accent = pickup ? _pickupColor : _returnColor;
    final done = pickup ? rental.status != RentalStatus.dipesan : rental.status == RentalStatus.dikembalikan;
    return TapScale(
      scaleDown: 0.98,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PenyewaanDetailScreen(orderId: order.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(left: BorderSide(color: accent, width: 4)),
          boxShadow: AppColors.cardShadow,
        ),
        padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 64,
            child: Column(children: [
              Text(
                (pickup ? rental.pickupTime : rental.returnTime) ?? DateFormat('dd').format(pickup ? rental.pickupDate : rental.returnDate),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              Text(
                (pickup ? rental.pickupTime : rental.returnTime) != null ? 'WIB' : DateFormat('MMM', 'id_ID').format(pickup ? rental.pickupDate : rental.returnDate).toUpperCase(),
                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              VgPill(
                label: pickup ? 'AMBIL' : 'KEMBALI',
                color: pickup ? AppColors.primary : _returnColor,
                background: AppColors.beige,
                fontSize: 10,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(order.customer.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                Icon(
                  done ? Icons.check_circle_outline_rounded : (rental.status == RentalStatus.terlambat ? Icons.error_outline_rounded : Icons.more_horiz_rounded),
                  size: 18,
                  color: done ? AppColors.success : (rental.status == RentalStatus.terlambat ? AppColors.danger : _busyColor),
                ),
              ]),
              Text('${order.totalQuantity} Stel ${order.headline}', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                VgPill(label: '#${order.orderNumber}', color: AppColors.textPrimary, background: AppColors.beige, fontSize: 10.5),
                VgPill(
                  label: done ? (pickup ? 'Selesai Diambil' : 'Sudah Kembali') : rental.status.label,
                  color: done ? AppColors.success : rental.status.color,
                  background: done ? AppColors.successBg : rental.status.background,
                  fontSize: 10.5,
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentTile({required this.appointment});

  Future<void> _actions(BuildContext context) async {
    final provider = context.read<AppointmentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final remove = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${appointment.typeLabel} · ${appointment.customerName}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('EEEE, d MMM yyyy · HH:mm', 'id_ID').format(appointment.startAt)}–${DateFormat('HH:mm').format(appointment.endAt)}${appointment.room != null ? ' · ${appointment.room}' : ''}',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
            if (appointment.note != null) ...[const SizedBox(height: 6), Text(appointment.note!, style: const TextStyle(fontSize: 12.5, color: AppColors.primary))],
            const SizedBox(height: 16),
            VgButton(label: 'Batalkan Jadwal', icon: Icons.event_busy_outlined, style: VgButtonStyle.soft, expanded: true, onPressed: () => Navigator.pop(ctx, true)),
          ]),
        ),
      ),
    );
    if (remove != true) return;
    final ok = await provider.remove(appointment.id);
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Jadwal dibatalkan.' : provider.errorMessage ?? 'Gagal membatalkan jadwal.')));
  }

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final accent = a.type == 'ambil' ? _pickupColor : (a.type == 'kembali' ? _returnColor : _apptColor);
    return TapScale(
      scaleDown: 0.98,
      onTap: () => _actions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: AppColors.surface, border: Border(left: BorderSide(color: accent, width: 4)), boxShadow: AppColors.cardShadow),
        padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 64,
            child: Column(children: [
              Text(DateFormat('HH:mm').format(a.startAt), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const Text('WIB', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              VgPill(label: a.typeLabel.split(' ').first.toUpperCase(), color: accent, background: AppColors.beige, fontSize: 9.5, padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3)),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.customerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (a.note != null) Text(a.note!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.primary)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (a.room != null) VgPill(label: a.room!, color: AppColors.textPrimary, background: AppColors.beige, fontSize: 10.5),
                if (a.staffName != null) VgPill(label: 'PJ: ${a.staffName}', color: AppColors.textPrimary, background: AppColors.beige, fontSize: 10.5),
                VgPill(label: '${a.durationMinutes} menit', color: AppColors.textPrimary, background: AppColors.beige, fontSize: 10.5),
              ]),
            ]),
          ),
          Icon(a.type == 'fitting' ? Icons.checkroom_rounded : (a.type == 'konsultasi' ? Icons.forum_outlined : Icons.local_shipping_outlined), size: 18, color: accent),
        ]),
      ),
    );
  }
}
