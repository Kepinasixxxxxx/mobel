import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vieguard_app/core/api/api_client.dart';
import 'package:vieguard_app/core/storage/token_storage.dart';
import 'package:vieguard_app/screens/auth/login_screen.dart';
import 'package:vieguard_app/state/auth_provider.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('Login screen renders fields, forgot password link, and submit button', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(apiClient: apiClient, tokenStorage: tokenStorage),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Lupa kata sandi?'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
