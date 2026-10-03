import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/main_shell.dart';
import 'state/appointment_provider.dart';
import 'state/auth_provider.dart';
import 'state/chat_provider.dart';
import 'state/notification_provider.dart';
import 'state/order_provider.dart';
import 'state/payment_provider.dart';
import 'state/product_provider.dart';
import 'state/rental_provider.dart';
import 'state/report_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  runApp(VieguardApp(apiClient: apiClient, tokenStorage: tokenStorage));
}

class VieguardApp extends StatelessWidget {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  const VieguardApp({super.key, required this.apiClient, required this.tokenStorage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient: apiClient, tokenStorage: tokenStorage)..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => OrderProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => RentalProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => PaymentProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => ProductProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => ChatProvider(apiClient: apiClient, tokenStorage: tokenStorage)),
        ChangeNotifierProvider(create: (_) => ReportProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => AppointmentProvider(apiClient: apiClient)),
      ],
      child: MaterialApp(
        title: 'VIEGUARD',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        scrollBehavior: const AppScrollBehavior(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const MainShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
