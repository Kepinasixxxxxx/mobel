import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/operations_models.dart';
import '../../state/order_provider.dart';
import '../../widgets/common/tap_scale.dart';
import '../../widgets/vg/vg_form.dart';
import '../../widgets/vg/vg_ui.dart';

const _templateHeader = ['Nama', 'L/P', 'Tinggi Badan (cm)', 'Ukuran', 'Peran'];
const _sizeOrder = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
const _maxHeight = {'XS': 150, 'S': 158, 'M': 166, 'L': 173};

String? _gender(String raw) {
  if (raw.startsWith('PR') || raw.startsWith('L')) return 'L';
  if (raw.startsWith('W') || raw.startsWith('P')) return 'P';
  return null;
}

String? heightWarning(SizeEntry e) {
  final max = _maxHeight[e.size];
  if (e.heightCm == null || max == null || e.heightCm! <= max) return null;
  return '${e.studentName}: TB ${e.heightCm} cm tapi memilih ${e.size}';
}

class SizeUploadScreen extends StatefulWidget {
  final String orderId;
  const SizeUploadScreen({super.key, required this.orderId});

  @override
  State<SizeUploadScreen> createState() => _SizeUploadScreenState();
}

class _SizeUploadScreenState extends State<SizeUploadScreen> {
  List<SizeEntry>? _entries;
  String? _fileName;
  List<String> _skipped = [];
  bool _saving = false;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    final orders = context.read<OrderProvider>();
    Future.microtask(() async {
      final order = await orders.fetchOrderDetail(widget.orderId);
      if (mounted && _entries == null) setState(() => _entries = [...?order?.sizeEntries]);
    });
  }

  int? _col(List<String> header, List<String> keys) {
    for (var i = 0; i < header.length; i++) {
      final h = header[i].toLowerCase();
      if (keys.any(h.contains)) return i;
    }
    return null;
  }

  Future<void> _import() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'csv']);
    if (picked.isEmpty) return;
    final file = picked.first;
    final bytes = await file.readAsBytes();

    List<List<String>> rows;
    try {
      if (file.extension?.toLowerCase() == 'csv') {
        rows = String.fromCharCodes(bytes).split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).map((l) => l.split(RegExp(r'[;,]')).map((c) => c.replaceAll('"', '').trim()).toList()).toList();
      } else {
        final book = xl.Excel.decodeBytes(bytes);
        final sheet = book.tables.values.first;
        rows = sheet.rows.map((r) => r.map((c) => c?.value?.toString().trim() ?? '').toList()).where((r) => r.any((c) => c.isNotEmpty)).toList();
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('File tidak bisa dibaca. Pastikan format .xlsx atau .csv sesuai template.')));
      return;
    }
    if (rows.length < 2) {
      messenger.showSnackBar(const SnackBar(content: Text('File kosong atau tidak memiliki baris data.')));
      return;
    }

    final header = rows.first;
    final name = _col(header, ['nama']);
    final size = _col(header, ['ukuran', 'size']);
    if (name == null || size == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Kolom "Nama" dan "Ukuran" wajib ada di baris pertama.')));
      return;
    }
    final gender = _col(header, ['l/p', 'jenis kelamin', 'gender']);
    final height = _col(header, ['tinggi', 'tb']);
    final role = _col(header, ['peran', 'posisi', 'role']);

    String cell(List<String> r, int? i) => i != null && i < r.length ? r[i] : '';
    final parsed = <SizeEntry>[];
    final skipped = <String>[];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      final student = cell(r, name);
      final s = cell(r, size).toUpperCase();
      if (student.isEmpty || s.isEmpty) {
        skipped.add('Baris ${i + 1}: nama atau ukuran kosong');
        continue;
      }
      final g = cell(r, gender).toUpperCase();
      parsed.add(SizeEntry(
        studentName: student,
        gender: _gender(g),
        heightCm: int.tryParse(cell(r, height).replaceAll(RegExp(r'[^0-9]'), '')),
        size: s,
        role: cell(r, role).isEmpty ? null : cell(r, role),
      ));
    }
    setState(() {
      _entries = parsed;
      _fileName = file.name;
      _skipped = skipped;
    });
  }

  Future<void> _template() async {
    final messenger = ScaffoldMessenger.of(context);
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: _templateHeader.join('\t')));
      messenger.showSnackBar(const SnackBar(content: Text('Judul kolom template disalin. Tempel di baris pertama Excel.')));
      return;
    }
    final book = xl.Excel.createExcel();
    final sheet = book[book.getDefaultSheet()!];
    sheet.appendRow(_templateHeader.map((h) => xl.TextCellValue(h)).toList());
    sheet.appendRow([xl.TextCellValue('Ahmad Fadhil'), xl.TextCellValue('L'), xl.IntCellValue(164), xl.TextCellValue('M'), xl.TextCellValue('Pasukan')]);
    final bytes = book.encode();
    if (bytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/template_ukuran_vieguard.xlsx';
    await File(path).writeAsBytes(bytes);
    await OpenFilex.open(path);
  }

  Future<void> _editEntry([int? index]) async {
    final existing = index != null ? _entries![index] : null;
    final nameCtrl = TextEditingController(text: existing?.studentName);
    final heightCtrl = TextEditingController(text: existing?.heightCm?.toString());
    final roleCtrl = TextEditingController(text: existing?.role);
    var size = existing?.size ?? 'M';
    var gender = existing?.gender ?? 'L';
    final saved = await showModalBottomSheet<SizeEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing == null ? 'Tambah Siswa' : 'Ubah Data Siswa', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 12),
            const VgLabel('Nama Siswa'),
            VgTextField(controller: nameCtrl, hint: 'Nama lengkap'),
            const SizedBox(height: 10),
            const VgLabel('Jenis Kelamin'),
            VgChoiceChips<String>(options: const [('L', 'Pria'), ('P', 'Wanita')], selected: gender, onSelected: (v) => setSheet(() => gender = v)),
            const SizedBox(height: 10),
            const VgLabel('Ukuran'),
            VgChoiceChips<String>(options: [for (final s in _sizeOrder) (s, s)], selected: size, onSelected: (v) => setSheet(() => size = v)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: VgTextField(controller: heightCtrl, hint: 'Tinggi', suffix: 'cm', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
              const SizedBox(width: 10),
              Expanded(child: VgTextField(controller: roleCtrl, hint: 'Peran (mis. Snare)')),
            ]),
            const SizedBox(height: 14),
            VgButton(
              label: 'Simpan',
              expanded: true,
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(
                  ctx,
                  SizeEntry(
                    studentName: nameCtrl.text.trim(),
                    gender: gender,
                    heightCm: int.tryParse(heightCtrl.text),
                    size: size,
                    role: roleCtrl.text.trim().isEmpty ? null : roleCtrl.text.trim(),
                  ),
                );
              },
            ),
          ]),
        ),
      ),
    );
    if (saved == null) return;
    setState(() {
      if (index == null) {
        _entries!.add(saved);
      } else {
        _entries![index] = saved;
      }
    });
  }

  Future<void> _save() async {
    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final ok = await provider.saveSizeEntries(widget.orderId, _entries!);
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(ok ? '${_entries!.length} data ukuran siswa tersimpan.' : provider.errorMessage ?? 'Gagal menyimpan data ukuran.')));
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().orderById(widget.orderId);
    final entries = _entries;
    if (order == null || entries == null) {
      return const Scaffold(backgroundColor: AppColors.background, appBar: VgBackBar(title: 'Data Ukuran Siswa'), body: Center(child: CircularProgressIndicator()));
    }

    final counts = <String, int>{};
    for (final e in entries) {
      counts[e.size] = (counts[e.size] ?? 0) + 1;
    }
    final sizes = counts.keys.toList()..sort((a, b) => (_sizeOrder.contains(a) ? _sizeOrder.indexOf(a) : 99).compareTo(_sizeOrder.contains(b) ? _sizeOrder.indexOf(b) : 99));
    final warnings = entries.map(heightWarning).whereType<String>().toList();
    final match = entries.length == order.totalQuantity;
    final shown = _showAll ? entries : entries.take(8).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VgBackBar(title: 'Data Ukuran Siswa'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(children: [
            VgPill(label: '#${order.orderNumber}', color: AppColors.primary, background: AppColors.beige, fontSize: 11),
            const Spacer(),
            Flexible(child: Text(order.customer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.primary))),
          ]),
          const SizedBox(height: 14),
          VgCard(
            child: Column(children: [
              TapScale(
                onTap: _import,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.beigeSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.goldDark, width: 1.2)),
                  child: const Column(children: [
                    Icon(Icons.upload_file_rounded, size: 34, color: Color(0xFF1E7B45)),
                    SizedBox(height: 6),
                    Text('Pilih file Excel (.xlsx / .csv)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    SizedBox(height: 2),
                    Text('Kolom: Nama, L/P, Tinggi Badan, Ukuran, Peran', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: AppColors.primary)),
                  ]),
                ),
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 12),
                VgInset(
                  child: Row(children: [
                    const VgIconBadge(icon: Icons.table_chart_outlined, color: AppColors.success, background: AppColors.successBg, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_fileName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text('${entries.length} baris terbaca${_skipped.isNotEmpty ? ' · ${_skipped.length} dilewati' : ''}', style: const TextStyle(fontSize: 11.5, color: AppColors.primary)),
                      ]),
                    ),
                    VgPill(label: _skipped.isEmpty ? 'Valid' : 'Periksa', color: _skipped.isEmpty ? AppColors.success : AppColors.warning, background: _skipped.isEmpty ? AppColors.successBg : AppColors.warningBg, dot: true, fontSize: 10.5),
                  ]),
                ),
              ],
              const SizedBox(height: 12),
              VgButton(label: kIsWeb ? 'Salin Format Template' : 'Unduh Template Excel', icon: Icons.download_rounded, style: VgButtonStyle.outline, expanded: true, height: 42, onPressed: _template),
            ]),
          ),
          VgCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(
                title: 'Hasil Validasi',
                subtitle: '${entries.length} siswa dari ${order.totalQuantity} stel pesanan',
                trailing: VgPill(
                  label: '${entries.length}/${order.totalQuantity}',
                  color: match ? AppColors.success : AppColors.warning,
                  background: match ? AppColors.successBg : AppColors.warningBg,
                ),
              ),
              if (sizes.isNotEmpty)
                VgInset(
                  color: AppColors.beigeSoft,
                  child: Row(children: [
                    for (final s in sizes)
                      Expanded(
                        child: Column(children: [
                          VgPill(label: s, color: AppColors.primary, background: AppColors.beige, fontSize: 11),
                          const SizedBox(height: 4),
                          Text('${counts[s]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ]),
                      ),
                  ]),
                ),
              if (!match && entries.isNotEmpty) ...[
                const SizedBox(height: 10),
                VgInset(
                  color: const Color(0xFFFFF4D6),
                  child: Text(
                    entries.length < order.totalQuantity
                        ? 'Masih kurang ${order.totalQuantity - entries.length} siswa dibanding jumlah stel pesanan.'
                        : 'Jumlah siswa melebihi pesanan sebanyak ${entries.length - order.totalQuantity}.',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
              for (final w in [...warnings, ..._skipped].take(5)) ...[
                const SizedBox(height: 8),
                VgInset(
                  color: const Color(0xFFFFF4D6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(w, style: const TextStyle(fontSize: 12, color: AppColors.primary))),
                  ]),
                ),
              ],
              if (entries.isEmpty) const Text('Belum ada data. Unggah file Excel atau tambah siswa manual.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ]),
          ),
          VgCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              VgCardTitle(title: 'Rincian Siswa', subtitle: 'Ketuk baris untuk mengubah', trailing: VgPill(label: '${shown.length} dari ${entries.length}', color: AppColors.primary, background: AppColors.beige)),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(children: [
                  Container(
                    color: AppColors.beige,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    child: const Row(children: [
                      SizedBox(width: 28, child: Text('NO', style: _head)),
                      Expanded(child: Text('NAMA SISWA', style: _head)),
                      SizedBox(width: 46, child: Center(child: Text('UKR', style: _head))),
                      SizedBox(width: 82, child: Text('PERAN', textAlign: TextAlign.right, style: _head)),
                    ]),
                  ),
                  for (var i = 0; i < shown.length; i++)
                    TapScale(
                      scaleDown: 0.99,
                      onTap: () => _editEntry(i),
                      child: Container(
                        color: i.isEven ? AppColors.surface : AppColors.beigeSoft,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Row(children: [
                          SizedBox(width: 28, child: Text((i + 1).toString().padLeft(2, '0'), style: const TextStyle(fontSize: 13, color: AppColors.primary))),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(shown[i].studentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              Text('${shown[i].genderLabel}${shown[i].heightCm != null ? ' · TB ${shown[i].heightCm}cm' : ''}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                            ]),
                          ),
                          SizedBox(
                            width: 46,
                            child: Center(child: VgPill(label: shown[i].size, color: AppColors.primary, background: heightWarning(shown[i]) != null ? AppColors.warningBg : AppColors.beige, fontSize: 11)),
                          ),
                          SizedBox(
                            width: 82,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: shown[i].role == null ? const Text('-') : VgPill(label: shown[i].role!, color: AppColors.textPrimary, background: AppColors.beige, fontSize: 10),
                            ),
                          ),
                        ]),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: VgButton(label: 'Tambah Siswa', icon: Icons.person_add_alt_rounded, style: VgButtonStyle.soft, height: 42, onPressed: () => _editEntry())),
                if (entries.length > 8) ...[
                  const SizedBox(width: 8),
                  Expanded(child: VgButton(label: _showAll ? 'Ringkas' : 'Lihat Semua', style: VgButtonStyle.outline, height: 42, onPressed: () => setState(() => _showAll = !_showAll))),
                ],
              ]),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: VgBottomBar(children: [
        VgButton(label: 'Simpan ke Pesanan', icon: Icons.task_alt_rounded, expanded: true, height: 52, loading: _saving, onPressed: entries.isEmpty ? null : _save),
        TextButton.icon(
          onPressed: () => openChatWithCustomer(context, order),
          icon: const Icon(Icons.chat_outlined, size: 18, color: AppColors.primary),
          label: const Text('Minta Revisi ke Pelanggan', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
      ]),
    );
  }
}

const _head = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.4);
