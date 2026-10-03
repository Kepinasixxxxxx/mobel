import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF7A0015);
  static const primaryDark = Color(0xFF5A000F);
  static const primaryLight = Color(0xFFA3182E);
  static const onPrimary = Colors.white;
  static const onPrimaryMuted = Colors.white70;
  static const onPrimaryFaint = Colors.white24;
  static const accent = Color(0xFFD9A33A);

  static const gold = Color(0xFFD9A33A);
  static const goldLight = Color(0xFFF2C766);
  static const goldDark = Color(0xFFB07A1C);
  static const onGold = Color(0xFF4A2A00);

  static const maroon = Color(0xFF7A0015);
  static const background = Color(0xFFFBF6EE);
  static const surface = Colors.white;
  static const surfaceHigh = Color(0xFFEFE2CE);
  static const beige = Color(0xFFEFE2CE);
  static const beigeSoft = Color(0xFFFAF3E8);
  static const textPrimary = Color(0xFF2B1A16);
  static const textSecondary = Color(0xFF8C7468);
  static const border = Color(0xFFEFE4D5);

  static const success = Color(0xFF1E8A4C);
  static const successBg = Color(0xFFDDF3E4);
  static const warning = Color(0xFF9A6700);
  static const warningBg = Color(0xFFFDF0C8);
  static const info = Color(0xFF3553B5);
  static const infoBg = Color(0xFFE6ECFF);
  static const danger = Color(0xFFC62828);
  static const dangerBg = Color(0xFFFDE4E4);

  static const goldGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [goldLight, gold, goldDark]);
  static const maroonGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8E0A20), Color(0xFF6A0012), Color(0xFF4A000B)]);

  static List<BoxShadow> get cardShadow => [BoxShadow(color: const Color(0xFF7A4A20).withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6))];
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => light;

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary);
    final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    const minTap = Size(64, 52);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
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
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
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
        fillColor: AppColors.beigeSoft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
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
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.surface, surfaceTintColor: Colors.transparent),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: AppColors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.gold)),
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
