import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/common/tap_scale.dart';
import '../akun/akun_screen.dart';
import '../beranda/beranda_screen.dart';
import '../chat/chat_list_screen.dart';
import '../penyewaan/penyewaan_list_screen.dart';
import '../pesanan/pesanan_list_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    BerandaScreen(),
    PesananListScreen(),
    PenyewaanListScreen(),
    ChatListScreen(),
    AkunScreen(),
  ];

  static const _items = [
    (Icons.grid_view_rounded, 'Beranda'),
    (Icons.receipt_long_rounded, 'Pesanan'),
    (Icons.vpn_key_outlined, 'Penyewaan'),
    (Icons.chat_bubble_outline_rounded, 'Chat'),
    (Icons.person_outline_rounded, 'Akun'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.goldLight, width: 1.2),
            boxShadow: [BoxShadow(color: const Color(0xFF7A4A20).withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = i == _index;
              final (icon, label) = _items[i];
              return Expanded(
                child: TapScale(
                  onTap: () => setState(() => _index = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: selected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(18)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(icon, size: 22, color: selected ? AppColors.goldLight : AppColors.primary),
                      const SizedBox(height: 3),
                      FittedBox(
                        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.onPrimary : AppColors.primary)),
                      ),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
