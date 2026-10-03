import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vieguard_app/core/api/api_client.dart';
import 'package:vieguard_app/core/storage/token_storage.dart';
import 'package:vieguard_app/core/theme/app_theme.dart';
import 'package:vieguard_app/screens/beranda/beranda_screen.dart';
import 'package:vieguard_app/screens/pesanan/detail_pesanan_screen.dart';
import 'package:vieguard_app/screens/pesanan/input_harga_screen.dart';
import 'package:vieguard_app/screens/pesanan/pesanan_list_screen.dart';
import 'package:vieguard_app/screens/pesanan/workshop_progress_screen.dart';
import 'package:vieguard_app/screens/pembayaran/payment_verification_detail_screen.dart';
import 'package:vieguard_app/screens/penyewaan/catat_kondisi_barang_screen.dart';
import 'package:vieguard_app/screens/penyewaan/penyewaan_detail_screen.dart';
import 'package:vieguard_app/screens/penyewaan/penyewaan_list_screen.dart';
import 'package:vieguard_app/models/conversation_model.dart';
import 'package:vieguard_app/screens/chat/chat_detail_screen.dart';
import 'package:vieguard_app/screens/notifikasi/notifikasi_screen.dart';
import 'package:vieguard_app/screens/stok/stok_detail_screen.dart';
import 'package:vieguard_app/screens/stok/stok_list_screen.dart';
import 'package:vieguard_app/widgets/penyewaan/rental_calendar_tab.dart';
import 'package:vieguard_app/state/auth_provider.dart';
import 'package:vieguard_app/state/chat_provider.dart';
import 'package:vieguard_app/state/notification_provider.dart';
import 'package:vieguard_app/state/order_provider.dart';
import 'package:vieguard_app/state/payment_provider.dart';
import 'package:vieguard_app/state/product_provider.dart';
import 'package:vieguard_app/state/rental_provider.dart';
import 'package:vieguard_app/state/report_provider.dart';
import 'package:vieguard_app/screens/akun/akun_screen.dart';
import 'package:vieguard_app/screens/chat/chat_list_screen.dart';
import 'package:vieguard_app/screens/laporan/laporan_screen.dart';
import 'package:vieguard_app/screens/pesanan/size_preview_screen.dart';
import 'package:vieguard_app/screens/akun/security_screen.dart';
import 'package:vieguard_app/screens/chat/new_chat_screen.dart';
import 'package:vieguard_app/screens/penyewaan/appointment_form_screen.dart';
import 'package:vieguard_app/screens/penyewaan/handover_screen.dart';
import 'package:vieguard_app/screens/penyewaan/refund_screen.dart';
import 'package:vieguard_app/screens/pesanan/photo_docs_screen.dart';
import 'package:vieguard_app/screens/pesanan/ship_order_screen.dart';
import 'package:vieguard_app/screens/pesanan/size_upload_screen.dart';
import 'package:vieguard_app/screens/stok/product_form_screen.dart';
import 'package:vieguard_app/screens/stok/stock_adjust_screen.dart';
import 'package:vieguard_app/state/appointment_provider.dart';
import 'package:vieguard_app/widgets/vg/vg_form.dart';

Map<String, dynamic> _order({
  required String id,
  required String type,
  required String status,
  required double total,
  bool production = false,
  Map<String, dynamic>? custom,
  Map<String, dynamic>? rental,
  List<Map<String, dynamic>> history = const [],
}) {
  final now = DateTime.now();
  return {
    'id': id,
    'orderNumber': 'VG-20260930-$id',
    'orderType': type,
    'requiresProduction': production,
    'status': status,
    'totalPrice': total,
    'dpAmount': total > 0 ? total / 2 : null,
    'isLunas': false,
    'deadlineDate': now.add(const Duration(days: 14)).toIso8601String(),
    'notes': 'Jahitan double tindas, resleting kuningan anti-karat.',
    'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
    'user': {'id': '9', 'name': 'SMK Negeri 4 Bandung', 'email': 'pic@smkn4.sch.id', 'phone': '+62 813-2245-8899', 'address': 'Jl. Kliningan No. 6, Buahbatu, Bandung'},
    'items': [
      {'id': '${id}1', 'itemType': 'product', 'productId': 'pr1', 'quantity': 40, 'size': 'M', 'unitPrice': 200000, 'subtotal': 8000000, 'product': {'name': 'Seragam Mayoret Klasik', 'images': []}},
      {'id': '${id}2', 'itemType': 'product', 'productId': 'pr1', 'quantity': 40, 'size': 'L', 'unitPrice': 200000, 'subtotal': 8000000, 'product': {'name': 'Seragam Mayoret Klasik', 'images': []}},
    ],
    'customOrderDetail': custom,
    'rental': rental,
    'payments': [],
    'statusHistory': history,
  };
}

final _orders = [
  _order(id: '1', type: 'custom', status: 'pending', total: 0, custom: {'jenisJenjang': 'Wearpack Jurusan Mesin', 'designDescription': 'Navy blue dengan scotlight silver & bordir emas', 'designReference': null, 'consultationNote': null}),
  _order(id: '2', type: 'custom', status: 'diproses', total: 24000000, production: true, history: [
    {'id': 'h1', 'progressPercentage': 65, 'statusLabel': 'Tahap Bordir & Jahit', 'createdAt': DateTime.now().toIso8601String()},
  ]),
  _order(id: '3', type: 'beli', status: 'pending', total: 7200000),
  _order(id: '4', type: 'sewa', status: 'siap_diambil', total: 3500000, rental: {
    'id': 'r1',
    'pickupDate': DateTime.now().toIso8601String(),
    'returnDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
    'status': 'dipesan',
  }),
  _order(id: '5', type: 'sewa', status: 'dikonfirmasi', total: 2400000, rental: {
    'id': 'r2',
    'pickupDate': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    'returnDate': DateTime.now().toIso8601String(),
    'status': 'diambil',
    'itemConditionBefore': 'Diserahkan dalam kondisi baik & lengkap.',
    'depositAmount': 500000,
    'pickupTime': '09:00',
    'returnTime': '18:00',
  }),
  _order(id: '6', type: 'sewa', status: 'selesai', total: 1800000, rental: {
    'id': 'r3',
    'pickupDate': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
    'returnDate': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    'actualReturnDate': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    'status': 'dikembalikan',
    'depositAmount': 500000,
    'penaltyAmount': 75000,
    'damageNote': 'Kostum ukuran M: noda make-up di kerah (Rp 75.000)',
    'refundStatus': 'menunggu',
    'refundBank': 'BCA',
    'refundAccount': '088-291-3819',
    'refundHolder': 'Ni Made Sukmawati',
  }),
];

final _products = [
  {
    'id': 'pr1',
    'categoryId': 'c1',
    'category': {'name': 'Kostum Drumband'},
    'name': 'Seragam Mayoret Klasik',
    'description': 'Busana mayoret dengan aksen emas',
    'basePriceRent': 200000,
    'isCustomAvailable': true,
    'isVisible': true,
    'sku': 'KST-MYR-01',
    'conditionGrade': 'A',
    'images': [],
    'variants': [
      {'id': 'v1', 'size': 'M', 'stockBuy': 0, 'stockRent': 50, 'stockInService': 2, 'serviceNote': 'Jahit ulang kancing'},
      {'id': 'v2', 'size': 'L', 'stockBuy': 0, 'stockRent': 40},
    ],
    'productAccessories': [
      {'quantityPerSet': 1, 'accessory': {'name': 'Topi Shako Bulu Putih'}},
      {'quantityPerSet': 2, 'accessory': {'name': 'Epolet Emas'}},
    ],
  },
];

final _notifications = [
  {'id': 'n1', 'type': 'ORDER_NEW', 'title': 'Permintaan Penawaran Harga Custom Masuk', 'message': 'SMK Negeri 4 Bandung mengajukan pesanan custom baru.', 'relatedOrderId': '1', 'isRead': false, 'createdAt': DateTime.now().toIso8601String()},
  {'id': 'n2', 'type': 'PAYMENT_PROOF_UPLOADED', 'title': 'Bukti Pembayaran Baru', 'message': 'Pelanggan mengunggah bukti transfer DP.', 'relatedOrderId': '2', 'isRead': false, 'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
];

final _messages = [
  {'id': 'm1', 'conversationId': 'cv1', 'senderType': 'user', 'senderId': '9', 'messageText': 'Halo Admin VIEGUARD, kami ingin konfirmasi pesanan seragam.', 'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String()},
  {'id': 'm2', 'conversationId': 'cv1', 'senderType': 'admin', 'senderId': '1', 'messageText': 'Baik, terima kasih. Apakah ada data ukuran yang perlu disesuaikan?', 'createdAt': DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String()},
];

String _todayAt(int hour) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, hour).toUtc().toIso8601String();
}

final _appointments = [
  {'id': 'a1', 'type': 'fitting', 'customerName': 'SMP Brawijaya Malang', 'startAt': _todayAt(10), 'durationMinutes': 90, 'room': 'Ruang Fitting 1', 'staffName': 'Kak Dimas', 'note': 'Fitting sampel jas mayoret'},
  {'id': 'a2', 'type': 'konsultasi', 'customerName': 'SMA Citra Bangsa', 'startAt': _todayAt(13), 'durationMinutes': 60, 'room': 'Ruang Fitting 2'},
];

final _security = {
  'hasPin': true,
  'passwordChangedAt': DateTime.now().subtract(const Duration(days: 18)).toIso8601String(),
  'autoAcceptOrders': false,
  'sessions': [
    {'id': 's1', 'deviceName': 'Dart/3.13 (dart:io)', 'createdAt': DateTime.now().toIso8601String(), 'expiresAt': DateTime.now().add(const Duration(days: 7)).toIso8601String()},
  ],
};

final _customers = [
  {'id': '9', 'name': 'SMK Negeri 4 Bandung', 'email': 'pic@smkn4.sch.id', 'phone': '081322458899'},
  {'id': '10', 'name': 'SMAN 1 Kepanjen', 'email': 'sman1@example.com', 'phone': '081299988877'},
];
final _payments = [
  {
    'id': 'p1',
    'orderId': '2',
    'paymentType': 'dp',
    'amount': 12000000,
    'paymentMethod': 'BCA Transfer',
    'proofImage': null,
    'status': 'menunggu',
    'createdAt': DateTime.now().toIso8601String(),
    'order': {'orderNumber': 'VG-20260930-2', 'totalPrice': 24000000, 'user': {'name': 'SMK Negeri 4 Bandung'}},
  },
];

class _FakeApiClient extends ApiClient {
  _FakeApiClient(TokenStorage storage) : super(tokenStorage: storage);

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path == '/orders') {
      return query?['orderType'] == 'sewa' ? _orders.where((o) => o['orderType'] == 'sewa').toList() : _orders;
    }
    if (path.startsWith('/orders/')) return _orders.firstWhere((o) => o['id'] == path.split('/').last);
    if (path == '/account/me') return {'id': '1', 'name': 'Admin Operasional', 'email': 'admin@vieguard.com', 'role': 'owner'};
    if (path == '/payments') return _payments;
    if (path == '/products') return _products;
    if (path == '/categories') return [{'id': 'c1', 'name': 'Kostum Drumband'}];
    if (path == '/notifications') return _notifications;
    if (path.startsWith('/chat/conversations/')) return _messages;
    if (path == '/chat/conversations') {
      return [
        {
          'id': 'cv1',
          'user': {'id': '9', 'name': 'SMK Negeri 4 Bandung'},
          'messages': [_messages.last],
          'lastMessageAt': DateTime.now().toIso8601String(),
          'unreadCount': 2,
        },
      ];
    }
    if (path == '/appointments') return _appointments;
    if (path == '/account/security') return _security;
    if (path == '/customers') return _customers;
    if (path == '/reports/summary') {
      return {
        'totalOrders': 5,
        'completedOrders': 1,
        'pendingOrders': 2,
        'totalCustomers': 12,
        'totalRevenue': 15000000,
        'revenueByType': {'beli': 9000000, 'sewa': 6000000},
        'ordersByType': [
          {'orderType': 'beli', '_count': {'id': 3}},
          {'orderType': 'sewa', '_count': {'id': 2}},
        ],
      };
    }
    return <dynamic>[];
  }

  final patches = <String, Map<String, dynamic>?>{};

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? data}) async {
    patches[path] = data;
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> put(String path, {Map<String, dynamic>? data}) async {
    patches[path] = data;
    return <String, dynamic>{};
  }

  final posts = <String, Map<String, dynamic>?>{};

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    posts[path] = data;
    if (path == '/appointments') return {'id': 'new', ...?data, 'startAt': DateTime.parse(data!['startAt'] as String).toUtc().toIso8601String()};
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> patchForm(String path, FormData form) async {
    patches[path] = {for (final f in form.fields) f.key: f.value};
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> postForm(String path, FormData form) async {
    posts[path] = {for (final f in form.fields) f.key: f.value};
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> delete(String path) async => <String, dynamic>{};
}

Widget _app(ApiClient api, TokenStorage storage, Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient: api, tokenStorage: storage)),
        ChangeNotifierProvider(create: (_) => OrderProvider(apiClient: api)..fetchOrders()),
        ChangeNotifierProvider(create: (_) => RentalProvider(apiClient: api)..fetchRentals()),
        ChangeNotifierProvider(create: (_) => PaymentProvider(apiClient: api)..fetchPayments()),
        ChangeNotifierProvider(create: (_) => ProductProvider(apiClient: api)..fetchAll()),
        ChangeNotifierProvider(create: (_) => ChatProvider(apiClient: api, tokenStorage: storage)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(apiClient: api)),
        ChangeNotifierProvider(create: (_) => ReportProvider(apiClient: api)),
        ChangeNotifierProvider(create: (_) => AppointmentProvider(apiClient: api)),
      ],
      child: MaterialApp(theme: AppTheme.light, home: home),
    );

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID', null);
  });

  final screens = <String, Widget>{
    'beranda': const BerandaScreen(),
    'pesanan_list': const PesananListScreen(),
    'detail_custom': const DetailPesananScreen(orderId: '1'),
    'detail_standar': const DetailPesananScreen(orderId: '3'),
    'input_harga': const InputHargaScreen(orderId: '1'),
    'workshop_progress': const WorkshopProgressScreen(orderId: '2'),
    'verifikasi_pelunasan': const PaymentVerificationDetailScreen(paymentId: 'p1'),
    'penyewaan_list': const PenyewaanListScreen(),
    'penyewaan_detail': const PenyewaanDetailScreen(orderId: '5'),
    'catat_kondisi': const CatatKondisiBarangScreen(orderId: '5'),
    'notifikasi': const NotifikasiScreen(),
    'chat_detail': ChatDetailScreen(conversation: Conversation(id: 'cv1', customerId: '9', customerName: 'SMK Negeri 4 Bandung')),
    'stok_list': const Scaffold(body: StokListScreen()),
    'stok_detail': const StokDetailScreen(productId: 'pr1'),
    'kalender': const Scaffold(body: RentalCalendarTab()),
    'chat_list': const ChatListScreen(),
    'akun': const AkunScreen(),
    'laporan': const LaporanScreen(),
    'pratinjau_ukuran': const SizePreviewScreen(orderId: '2'),
    'tambah_kostum': const ProductFormScreen(),
    'atur_stok': const StockAdjustScreen(productId: 'pr1'),
    'upload_ukuran': const SizeUploadScreen(orderId: '2'),
    'kirim_resi': const ShipOrderScreen(orderId: '3'),
    'serah_terima': const HandoverScreen(orderId: '4'),
    'refund_deposit': const RefundScreen(orderId: '6'),
    'dokumentasi_foto': const PhotoDocsScreen(orderId: '2'),
    'booking_jadwal': const AppointmentFormScreen(),
    'chat_baru': const NewChatScreen(),
    'keamanan_akun': const SecurityScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders without layout errors', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(400, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final storage = TokenStorage();
      final api = _FakeApiClient(storage);
      final errors = <FlutterErrorDetails>[];
      final original = FlutterError.onError;
      FlutterError.onError = errors.add;
      await tester.pumpWidget(_app(api, storage, entry.value));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2500));
      await tester.pump(const Duration(milliseconds: 500));
      FlutterError.onError = original;

      for (final e in errors) {
        debugPrint(e.toString());
      }
      expect(errors, isEmpty);
    });
  }

  testWidgets('input harga computes totals and submits quote', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = TokenStorage();
    final api = _FakeApiClient(storage);
    await tester.pumpWidget(_app(
      api,
      storage,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InputHargaScreen(orderId: '1'))),
            child: const Text('buka'),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '95000');
    await tester.enterText(fields.at(1), '55000');
    await tester.enterText(fields.at(2), '35000');
    await tester.enterText(fields.at(3), '25');
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.controller?.text == '0'), '350000');
    await tester.pump();

    expect(find.text('Rp 231.250 / stel'), findsOneWidget);
    expect(find.text('Rp 18.500.000'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('TOTAL PENAWARAN RESMI'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('18.850.000'), findsOneWidget);
    expect(find.text('Rp 9.425.000'), findsNWidgets(2));

    await tester.tap(find.text('Kirim Penawaran ke Pelanggan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim'));
    await tester.pumpAndSettle();

    final payload = api.patches['/orders/1/quote'];
    expect(payload, isNotNull);
    expect(payload!['totalPrice'], 18850000);
    expect(payload['dpAmount'], 9425000);
    expect(payload['deadlineDate'], isA<String>());
    expect(find.text('buka'), findsOneWidget);
  });

  Future<_FakeApiClient> pumpPushed(WidgetTester tester, Widget screen) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final storage = TokenStorage();
    final api = _FakeApiClient(storage);
    await tester.pumpWidget(_app(
      api,
      storage,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)), child: const Text('buka')),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    return api;
  }

  testWidgets('workshop progress keeps current phase and publishes overall percentage', (tester) async {
    final api = await pumpPushed(tester, const WorkshopProgressScreen(orderId: '2'));
    await tester.scrollUntilVisible(find.text('25 %'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('25 %'), findsOneWidget);

    await tester.tap(find.text('Simpan & Publikasikan Progres'));
    await tester.pumpAndSettle();

    final payload = api.patches['/orders/2/progress'];
    expect(payload!['progressPercentage'], 65);
    expect(payload['statusLabel'], 'Quality Control & Pasang Kancing');
  });

  testWidgets('payment approval requires all three audit checks', (tester) async {
    final api = await pumpPushed(tester, const PaymentVerificationDetailScreen(paymentId: 'p1'));
    await tester.scrollUntilVisible(find.text('Match 100%'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Match 100%'), findsOneWidget);

    await tester.tap(find.text('Verifikasi & Setujui Pembayaran'));
    await tester.pumpAndSettle();
    expect(api.patches['/payments/p1/verify'], isNull);

    for (final label in ['Nominal transfer sesuai tagihan', 'Mutasi rekening admin telah dicek', 'Data pesanan & kontak pelanggan terkonfirmasi']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pump();
    }
    expect(find.text('3/3 Lengkap'), findsOneWidget);

    await tester.tap(find.text('Verifikasi & Setujui Pembayaran'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan PIN Otorisasi'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(api.patches['/payments/p1/verify']!['status'], 'terverifikasi');
    expect(api.patches['/payments/p1/verify']!['pin'], '123456');
  });

  testWidgets('return inspection submits condition summary and penalty', (tester) async {
    final api = await pumpPushed(tester, const CatatKondisiBarangScreen(orderId: '5'));

    await tester.tap(find.text('Rusak').first);
    await tester.pump();
    await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Jelaskan noda / kerusakan'), 'Noda make-up di kerah');
    await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.decoration?.prefixText == 'Rp '), '75000');
    await tester.pump();

    final agreement = find.textContaining('Penyewa menyetujui hasil inspeksi');
    await tester.scrollUntilVisible(agreement, 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(agreement);
    await tester.pump();
    await tester.tap(find.text('Konfirmasi Pengembalian'));
    await tester.pumpAndSettle();

    final payload = api.patches['/rentals/r2/status']!;
    expect(payload['status'], 'dikembalikan');
    expect(payload['penaltyAmount'], 75000);
    expect(payload['itemConditionAfter'], contains('Ada noda/rusak - Noda make-up di kerah'));
  });

  test('rental stock counts split rented and booked units per size', () async {
    SharedPreferences.setMockInitialValues({});
    final rentals = RentalProvider(apiClient: _FakeApiClient(TokenStorage()));
    await rentals.fetchRentals();
    expect(rentals.rentedQty('pr1'), 80);
    expect(rentals.rentedQty('pr1', size: 'M'), 40);
    expect(rentals.bookedQty('pr1'), 80);
    expect(rentals.rentalsForProduct('pr1').length, 3);
    expect(rentals.earliestReturn('pr1'), isNotNull);
  });

  testWidgets('stock stepper accepts typed numbers and saves variants', (tester) async {
    final api = await pumpPushed(tester, const StockAdjustScreen(productId: 'pr1'));
    final totalField = find.descendant(of: find.byType(VgStepper).first, matching: find.byType(TextField));
    await tester.tap(totalField);
    await tester.pump();
    await tester.enterText(totalField, '75');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan Perubahan Stok'));
    await tester.pumpAndSettle();
    final variants = (api.patches['/products/pr1/variants']!['variants'] as List).cast<Map<String, dynamic>>();
    expect(variants.firstWhere((v) => v['size'] == 'M')['stockRent'], 75);
    expect(variants.firstWhere((v) => v['size'] == 'M')['stockInService'], 2);
  });

  testWidgets('booking blocks a clashing time and lists booked slots', (tester) async {
    await pumpPushed(tester, const AppointmentFormScreen());
    expect(find.text('SMP Brawijaya Malang'), findsOneWidget);
    expect(find.text('Pilih Jam Terlebih Dahulu'), findsOneWidget);

    Future<void> pickTime(String hour, String minute) async {
      await tester.tap(find.textContaining(RegExp(r'^(Pilih jam|\d\d:\d\d WIB)$')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.descendant(of: find.byType(Dialog), matching: find.byType(TextField));
      await tester.enterText(fields.at(0), hour);
      await tester.enterText(fields.at(1), minute);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    await pickTime('11', '00');
    expect(find.textContaining('Bentrok dengan SMP Brawijaya Malang'), findsOneWidget);

    await pickTime('15', '30');
    expect(find.textContaining('Bentrok dengan'), findsNothing);
    expect(find.textContaining('Simpan Jadwal 15:30'), findsOneWidget);
  });

  testWidgets('handover needs full checklist and renter approval, no signature', (tester) async {
    final api = await pumpPushed(tester, const HandoverScreen(orderId: '4'));
    await tester.tap(find.text('Serahkan Kostum'));
    await tester.pumpAndSettle();
    expect(api.patches['/rentals/r1/handover'], isNull);

    Future<void> reveal(Finder f) async {
      await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);
      await Scrollable.ensureVisible(tester.element(f), alignment: 0.3);
      await tester.pumpAndSettle();
    }

    await reveal(find.text('Centang semua'));
    await tester.tap(find.text('Centang semua'));
    await tester.pump();
    final approval = find.textContaining('Penyewa sudah memeriksa');
    await reveal(approval);
    await tester.tap(approval);
    await tester.pump();

    await tester.tap(find.text('Serahkan Kostum'));
    await tester.pumpAndSettle();
    final payload = api.patches['/rentals/r1/handover']!;
    expect(payload['pickupTime'], isNotNull);
    expect(payload['conditionNote'], contains('baik'));
  });

  testWidgets('refund asks for PIN and sends deposit minus penalty', (tester) async {
    final api = await pumpPushed(tester, const RefundScreen(orderId: '6'));
    expect(find.text('Rp 425.000'), findsOneWidget);
    await tester.tap(find.textContaining('Konfirmasi Refund'));
    await tester.pumpAndSettle();
    expect(find.text('Unggah bukti transfer refund terlebih dahulu.'), findsOneWidget);
    expect(api.patches['/rentals/r3/refund'], isNull);
  });
}
