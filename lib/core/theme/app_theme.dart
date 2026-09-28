import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFFE9B949);
  static const primaryDark = Color(0xFFC8922A);
  static const primaryLight = Color(0xFFFFE27A);
  static const onPrimary = Color(0xFF2A0006);
  static const onPrimaryMuted = Color(0xB32A0006);
  static const onPrimaryFaint = Color(0x3D2A0006);
  static const accent = Color(0xFFFFE27A);

  static const maroon = Color(0xFF7A0015);
  static const background = Color(0xFF1A0205);
  static const surface = Color(0xFF4F0F1B);
  static const surfaceHigh = Color(0xFF631C28);
  static const textPrimary = Color(0xFFFFF4E0);
  static const textSecondary = Color(0xFFC99A8F);
  static const border = Color(0xFF8A5530);

  static const success = Color(0xFFE9B949);
  static const successBg = Color(0x33E9B949);
  static const warning = Color(0xFFFFF4E0);
  static const warningBg = Color(0x24FFF4E0);
  static const info = Color(0xFFFFF4E0);
  static const infoBg = Color(0x24FFF4E0);
  static const danger = Color(0xFFFF6B6B);

  static const goldGradient = LinearGradient(colors: [primaryDark, primaryLight, primaryDark]);
  static const maroonGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [maroon, surface]);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => dark;

  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary);
    final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(30));
    const minTap = Size(64, 52);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.accent,
        onSecondary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        outline: AppColors.border,
      ),
      textTheme: text,
      iconTheme: const IconThemeData(color: AppColors.primary),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: _FadeSlideTransitionsBuilder(),
        TargetPlatform.iOS: _FadeSlideTransitionsBuilder(),
        TargetPlatform.windows: _FadeSlideTransitionsBuilder(),
        TargetPlatform.macOS: _FadeSlideTransitionsBuilder(),
        TargetPlatform.linux: _FadeSlideTransitionsBuilder(),
      }),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.border)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceHigh,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          minimumSize: minTap,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: pill,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(64, 48),
          shape: pill,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary, minimumSize: const Size(48, 44)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary)),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500, color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.border,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.border)),
        titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.surface, surfaceTintColor: Colors.transparent),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.primaryDark)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary, linearTrackColor: AppColors.surfaceHigh),
      sliderTheme: const SliderThemeData(activeTrackColor: AppColors.primary, thumbColor: AppColors.primaryLight, inactiveTrackColor: AppColors.surfaceHigh),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.surfaceHigh),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.primary, textColor: AppColors.textPrimary),
      popupMenuTheme: const PopupMenuThemeData(color: AppColors.surfaceHigh),
      dropdownMenuTheme: const DropdownMenuThemeData(menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(AppColors.surfaceHigh))),
    );
  }
}

class _FadeSlideTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final exit = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.6).animate(exit),
      child: SlideTransition(
        position: Tween(begin: Offset.zero, end: const Offset(-0.08, 0)).animate(exit),
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(curved),
            child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(curved), child: child),
          ),
        ),
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
