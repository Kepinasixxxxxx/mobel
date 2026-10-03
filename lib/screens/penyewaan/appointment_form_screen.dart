import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/operations_models.dart';
import '../../models/order_model.dart';
import '../../models/order_status.dart';
import '../../state/appointment_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_form.dart';
import '../../widgets/vg/vg_ui.dart';

const _rooms = ['Ruang Fitting 1', 'Ruang Fitting 2', 'Meja Serah Terima'];
const _durations = [30, 60, 90, 120];

String _hm(DateTime d) => DateFormat('HH:mm').format(d);

class AppointmentFormScreen extends StatefulWidget {
  final DateTime? initialDate;
  const AppointmentFormScreen({super.key, this.initialDate});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _customer = TextEditingController();
  final _staff = TextEditingController();
  final _note = TextEditingController();
  String _type = 'fitting';
  Order? _order;
  late DateTime _date;
  TimeOfDay? _time;
  int _duration = 60;
  String? _room = _rooms.first;
  List<Appointment> _booked = [];
  bool _loadingDay = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    _date = DateTime(base.year, base.month, base.day);
    _staff.text = context.read<AuthProvider>().currentAdmin?.name ?? '';
    Future.microtask(() {
      if (!mounted) return;
      final orders = context.read<OrderProvider>();
      if (orders.orders.isEmpty) orders.fetchOrders();
      _loadDay();
    });
  }

  @override
  void dispose() {
    _customer.dispose();
    _staff.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadDay() async {
    setState(() => _loadingDay = true);
    final list = await context.read<AppointmentProvider>().fetchDay(_date);
    if (mounted) {
      setState(() {
        _booked = list;
        _loadingDay = false;
      });
    }
  }

  DateTime? get _start => _time == null ? null : DateTime(_date.year, _date.month, _date.day, _time!.hour, _time!.minute);

  Appointment? get _clash {
    final start = _start;
    if (start == null) return null;
    final end = start.add(Duration(minutes: _duration));
    for (final a in _booked) {
      final overlap = a.startAt.isBefore(end) && a.endAt.isAfter(start);
      final sameRoom = _room == null || a.room == null || a.room == _room;
      if (overlap && sameRoom) return a;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 180)));
    if (picked == null) return;
    setState(() => _date = picked);
    _loadDay();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickOrder(List<Order> orders) async {
    final picked = await showModalBottomSheet<Order>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          children: [
            const Text('Pilih Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 12),
            for (final o in orders)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TapScale(
                  onTap: () => Navigator.pop(ctx, o),
                  child: VgInset(
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(o.customer.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          Text('#${o.orderNumber} · ${o.headline}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                        ]),
                      ),
                      VgPill(label: o.orderType.label, color: AppColors.info, background: AppColors.infoBg, fontSize: 10),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _order = picked;
      _customer.text = picked.customer.name;
    });
  }

  Future<void> _save() async {
    final provider = context.read<AppointmentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_customer.text.trim().isEmpty || _start == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Isi nama pelanggan dan jam jadwal.')));
      return;
    }
    setState(() => _saving = true);
    final created = await provider.create(
      type: _type,
      orderId: _order?.id,
      customerName: _customer.text.trim(),
      startAt: _start!,
      durationMinutes: _duration,
      room: _room,
      staffName: _staff.text.trim().isEmpty ? null : _staff.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (created == null) {
      messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Gagal menyimpan jadwal.')));
      _loadDay();
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text('Jadwal ${created.typeLabel} ${_hm(created.startAt)} tersimpan.')));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders.where((o) => o.status != OrderStatus.selesai && o.status != OrderStatus.dibatalkan).toList();
    final clash = _clash;
    final start = _start;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Booking Jadwal'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const VgLabel('Jenis Jadwal'),
              VgChoiceChips<String>(
                options: const [('fitting', 'Fitting'), ('ambil', 'Ambil Sewa'), ('kembali', 'Kembali Sewa'), ('konsultasi', 'Konsultasi')],
                selected: _type,
                onSelected: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 14),
              VgLabel(
                'Pelanggan / Pesanan',
                trailing: TapScale(
                  onTap: () => _pickOrder(orders),
                  child: const Text('Pilih dari pesanan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ),
              VgTextField(controller: _customer, icon: Icons.person_search_outlined, hint: 'Nama pelanggan / sekolah', onChanged: (_) => setState(() => _order = null)),
              if (_order != null) ...[
                const SizedBox(height: 6),
                VgPill(label: 'Terhubung ke #${_order!.orderNumber}', color: AppColors.success, background: AppColors.successBg, icon: Icons.link_rounded, fontSize: 11),
              ],
              const SizedBox(height: 14),
              const VgLabel('Tanggal'),
              TapScale(
                onTap: _pickDate,
                child: VgInset(
                  color: AppColors.beigeSoft,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  child: Row(children: [
                    const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_date), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                    const Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.primary),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const VgLabel('Jam Mulai'),
                    TapScale(
                      onTap: _pickTime,
                      child: VgInset(
                        color: clash != null ? AppColors.dangerBg : AppColors.beigeSoft,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        child: Row(children: [
                          Icon(Icons.schedule_rounded, size: 20, color: clash != null ? AppColors.danger : AppColors.primary),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              start == null ? 'Pilih jam' : '${_hm(start)} WIB',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: clash != null ? AppColors.danger : AppColors.textPrimary),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const VgLabel('Selesai'),
                    VgInset(
                      color: AppColors.beige,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      child: Text(start == null ? '-' : '${_hm(start.add(Duration(minutes: _duration)))} WIB', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              const VgLabel('Durasi'),
              VgChoiceChips<int>(options: [for (final d in _durations) (d, d < 60 ? '$d menit' : '${d ~/ 60}${d % 60 == 0 ? '' : ',5'} jam')], selected: _duration, onSelected: (v) => setState(() => _duration = v)),
              if (clash != null) ...[
                const SizedBox(height: 12),
                VgInset(
                  color: AppColors.dangerBg,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.event_busy_outlined, size: 18, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bentrok dengan ${clash.customerName} (${_hm(clash.startAt)}–${_hm(clash.endAt)}${clash.room != null ? ', ${clash.room}' : ''}). Pilih jam atau ruang lain.',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.danger, height: 1.4),
                      ),
                    ),
                  ]),
                ),
              ],
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Jadwal Sudah Terisi',
                subtitle: DateFormat('d MMMM yyyy', 'id_ID').format(_date),
                trailing: VgPill(label: '${_booked.length} Jadwal', color: AppColors.primary, background: AppColors.beige),
              ),
              if (_loadingDay)
                const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))
              else if (_booked.isEmpty)
                const Text('Belum ada jadwal di tanggal ini. Semua jam masih kosong.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))
              else
                for (final a in _booked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: VgInset(
                      color: identical(a, clash) ? AppColors.dangerBg : AppColors.beige,
                      child: Row(children: [
                        SizedBox(
                          width: 64,
                          child: Column(children: [
                            Text(_hm(a.startAt), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            Text('s/d ${_hm(a.endAt)}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                          ]),
                        ),
                        Container(width: 1, height: 32, color: AppColors.border),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            Text('${a.typeLabel}${a.room != null ? ' · ${a.room}' : ''}', style: const TextStyle(fontSize: 11.5, color: AppColors.primary)),
                          ]),
                        ),
                        if (identical(a, clash)) const Icon(Icons.block_rounded, size: 18, color: AppColors.danger),
                      ]),
                    ),
                  ),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const VgLabel('Ruang'),
              VgChoiceChips<String?>(options: [for (final r in _rooms) (r, r)], selected: _room, onSelected: (v) => setState(() => _room = v)),
              const SizedBox(height: 12),
              const VgLabel('Petugas'),
              VgTextField(controller: _staff, icon: Icons.badge_outlined, hint: 'Nama petugas'),
              const SizedBox(height: 12),
              const VgLabel('Catatan'),
              VgTextField(controller: _note, maxLines: 3, hint: 'Contoh: bawa sampel ukuran M dan L'),
            ]),
          ),
          const VgInset(
            child: Row(children: [
              Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(child: Text('Jadwal muncul di Kalender Rental sebagai agenda harian.', style: TextStyle(fontSize: 12, color: AppColors.primary))),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: VgBottomBar(children: [
        VgButton(
          label: start == null ? 'Pilih Jam Terlebih Dahulu' : 'Simpan Jadwal ${_hm(start)} · ${Formatters.date(_date)}',
          icon: Icons.event_available_outlined,
          expanded: true,
          height: 52,
          loading: _saving,
          onPressed: start == null || clash != null ? null : _save,
        ),
        const SizedBox(height: 6),
      ]),
    );
  }
}
