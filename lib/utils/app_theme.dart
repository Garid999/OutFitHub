import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme notifier (persists preference) ────────────────────────────────────

class ThemeNotifier extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeNotifier() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDark);
    notifyListeners();
  }
}

// ─── Context-aware colors ─────────────────────────────────────────────────────

class AppColors {
  final Color background;
  final Color surface;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color primary;
  final bool isDark;

  const AppColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.primary,
    required this.isDark,
  });

  static const light = AppColors(
    background:    Color(0xFFFCF6F5),
    surface:       Color(0xFFFFFFFF),
    card:          Color(0xFFF5EDEB),
    textPrimary:   Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6B),
    border:        Color(0xFFE0D5D0),
    primary:       Color(0xFF990011),
    isDark:        false,
  );

  static const dark = AppColors(
    background:    Color(0xFF0D0D0D),
    surface:       Color(0xFF1A1A1A),
    card:          Color(0xFF242424),
    textPrimary:   Color(0xFFEDEDED),
    textSecondary: Color(0xFF8A8A8A),
    border:        Color(0xFF2C2C2C),
    primary:       Color(0xFFE53935),
    isDark:        true,
  );
}

extension AppColorsExt on BuildContext {
  AppColors get c {
    final dark = Theme.of(this).brightness == Brightness.dark;
    return dark ? AppColors.dark : AppColors.light;
  }
}

// ─── AppTheme (keep static consts for admin/non-context widgets) ──────────────

class AppTheme {
  // Light constants (used in hardcoded admin panel etc.)
  static const Color primary       = Color(0xFF990011);
  static const Color primaryDark   = Color(0xFF6B0009);
  static const Color background    = Color(0xFFFCF6F5);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color cardColor     = Color(0xFFF5EDEB);
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color border        = Color(0xFFE0D5D0);

  // Dark constants
  static const Color darkBg      = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard    = Color(0xFF242424);
  static const Color darkBorder  = Color(0xFF2C2C2C);
  static const Color darkRed     = Color(0xFFE53935);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    dividerColor: border,
    cardColor: cardColor,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: primaryDark,
      surface: surface,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkRed,
    scaffoldBackgroundColor: darkBg,
    dividerColor: darkBorder,
    cardColor: darkCard,
    colorScheme: const ColorScheme.dark(
      primary: darkRed,
      secondary: Color(0xFFB71C1C),
      surface: darkSurface,
      onSurface: Color(0xFFEDEDED),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFFEDEDED)),
      titleTextStyle: TextStyle(
        color: Color(0xFFEDEDED),
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: darkRed,
      unselectedItemColor: Color(0xFF8A8A8A),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
      ),
    ),
  );
}
