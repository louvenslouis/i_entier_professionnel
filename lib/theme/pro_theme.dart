import 'package:flutter/material.dart';

class ProColors {
  static const ink = Color(0xFF102A43);
  static const muted = Color(0xFF637381);
  static const canvas = Color(0xFFF4F7F8);
  static const border = Color(0xFFDCE6E8);
  static const primary = Color(0xFF087F8C);
  static const primaryDark = Color(0xFF075B63);
  static const primarySoft = Color(0xFFE4F5F5);
  static const accent = Color(0xFFFFB35C);
  static const navy = Color(0xFF0C3440);
  static const success = Color(0xFF18875D);
}

ThemeData buildProTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: ProColors.canvas,
  fontFamily: 'Arial',
  colorScheme: ColorScheme.fromSeed(
    seedColor: ProColors.primary,
    primary: ProColors.primary,
    secondary: ProColors.accent,
    surface: Colors.white,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: ProColors.ink,
      fontWeight: FontWeight.w900,
      letterSpacing: -.8,
    ),
    headlineMedium: TextStyle(
      color: ProColors.ink,
      fontWeight: FontWeight.w900,
      letterSpacing: -.5,
    ),
    titleLarge: TextStyle(color: ProColors.ink, fontWeight: FontWeight.w800),
    bodyLarge: TextStyle(color: ProColors.ink, height: 1.45),
    bodyMedium: TextStyle(color: ProColors.muted, height: 1.4),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: ProColors.ink,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ProColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ProColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ProColors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFC9362B)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: ProColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ProColors.ink,
      minimumSize: const Size(0, 50),
      side: const BorderSide(color: ProColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
);

class ProBrand extends StatelessWidget {
  final bool light;

  const ProBrand({super.key, this.light = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: light ? Colors.white : ProColors.primary,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          Icons.add_rounded,
          color: light ? ProColors.primaryDark : Colors.white,
          size: 29,
        ),
      ),
      const SizedBox(width: 11),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'i-ENTIER',
            style: TextStyle(
              color: light ? Colors.white : ProColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
          Text(
            'PROFESSIONNEL',
            style: TextStyle(
              color: light ? const Color(0xFFFFD59F) : ProColors.primary,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    ],
  );
}

class ProPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ProPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ProColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A12343B),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );
}
