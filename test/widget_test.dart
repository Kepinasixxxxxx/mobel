import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:vieguard_app/core/api/api_client.dart';
import 'package:vieguard_app/core/storage/token_storage.dart';
import 'package:vieguard_app/core/theme/app_theme.dart';
import 'package:vieguard_app/screens/auth/login_screen.dart';
import 'package:vieguard_app/state/auth_provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('Login screen renders email/password fields and a submit button', (WidgetTester tester) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(apiClient: apiClient, tokenStorage: tokenStorage),
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VIEGUARD Admin'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email Admin'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);
  });
}
