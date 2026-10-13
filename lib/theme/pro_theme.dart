// Flutter 3.44 moved CupertinoPageTransitionsBuilder out of material.dart.
// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Palette partagée par l’expérience I-ENTIER.
abstract final class ProColors {
  static const primary = Color(0xFF246B56);
  static const primaryDark = Color(0xFF194D3E);
  static const primarySoft = Color(0xFFE8F0E8);
  static const teal = Color(0xFF477A68);
  static const navy = Color(0xFF1D322A);
  static const ink = Color(0xFF293C34);
  static const muted = Color(0xFF606D64);
  static const border = Color(0xFFDDE2D9);
  static const canvas = Color(0xFFF6F5F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEFEEE8);
  static const tealSoft = Color(0xFFE8EFE5);
  static const disabled = Color(0xFFD9DED5);
  static const error = Color(0xFFB44335);
  static const success = Color(0xFF357351);
  static const accent = Color(0xFFC7D5AC);
  static const danger = error;
  static const warning = Color(0xFF95632B);
}

/// Même finition pour les cartes, qu’elles utilisent Material ou Container.
abstract final class ProDecorations {
  static const controlRadius = BorderRadius.all(Radius.circular(12));
  static const cardRadius = BorderRadius.all(Radius.circular(16));
  static const card = BoxDecoration(
    color: ProColors.surface,
    borderRadius: cardRadius,
    border: Border.fromBorderSide(BorderSide(color: ProColors.border)),
  );
  static const cardShadow = [
    BoxShadow(color: Color(0x061D322A), blurRadius: 12, offset: Offset(0, 3)),
  ];
  static final raisedCard = card.copyWith(boxShadow: cardShadow);
}

/// Fondation Material 3 commune à tous les écrans.
abstract final class ProTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: ProColors.primary,
          brightness: Brightness.light,
          primary: ProColors.primary,
          secondary: ProColors.teal,
          error: ProColors.error,
          surface: ProColors.surface,
        ).copyWith(
          onPrimary: ProColors.surface,
          primaryContainer: ProColors.primarySoft,
          onPrimaryContainer: ProColors.primaryDark,
          secondaryContainer: ProColors.tealSoft,
          onSecondaryContainer: ProColors.success,
          onSurface: ProColors.ink,
          onSurfaceVariant: ProColors.muted,
          outline: ProColors.border,
          outlineVariant: const Color(0xFFECEEE6),
          surfaceContainerLowest: ProColors.surface,
          surfaceContainerLow: const Color(0xFFFAFAF6),
          surfaceContainer: ProColors.surfaceMuted,
          surfaceContainerHigh: const Color(0xFFE8EBE2),
          surfaceContainerHighest: const Color(0xFFE1E5DB),
        );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: ProColors.canvas,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    return base.copyWith(
      // Conserve les tailles et métriques de la typographie Material.
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall!.copyWith(
          color: ProColors.navy,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.1,
        ),
        headlineLarge: base.textTheme.headlineLarge!.copyWith(
          color: ProColors.navy,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
        ),
        headlineMedium: base.textTheme.headlineMedium!.copyWith(
          color: ProColors.navy,
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
        ),
        headlineSmall: base.textTheme.headlineSmall!.copyWith(
          color: ProColors.navy,
          fontWeight: FontWeight.w700,
          letterSpacing: -.25,
        ),
        titleLarge: base.textTheme.titleLarge!.copyWith(
          color: ProColors.navy,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium!.copyWith(
          color: ProColors.navy,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: base.textTheme.titleSmall!.copyWith(
          color: ProColors.navy,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge!.copyWith(
          color: ProColors.ink,
          height: 1.45,
        ),
        bodyMedium: base.textTheme.bodyMedium!.copyWith(
          color: ProColors.ink,
          height: 1.4,
        ),
        bodySmall: base.textTheme.bodySmall!.copyWith(
          color: ProColors.muted,
          height: 1.35,
        ),
        labelLarge: base.textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.w700,
        ),
        labelMedium: base.textTheme.labelMedium!.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ProColors.canvas,
        foregroundColor: ProColors.navy,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 64,
        iconTheme: IconThemeData(color: ProColors.navy),
        actionsIconTheme: IconThemeData(color: ProColors.navy),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.navy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: ProColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: ProDecorations.cardRadius,
          side: const BorderSide(color: ProColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ProColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.muted,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.muted,
        ),
        prefixIconColor: WidgetStateColor.resolveWith(_inputIconColor),
        suffixIconColor: WidgetStateColor.resolveWith(_inputIconColor),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.primary,
          fontWeight: FontWeight.w700,
        ),
        errorMaxLines: 2,
        disabledBorder: const OutlineInputBorder(
          borderRadius: ProDecorations.controlRadius,
          borderSide: BorderSide(color: ProColors.border),
        ),
        border: OutlineInputBorder(
          borderRadius: ProDecorations.controlRadius,
          borderSide: const BorderSide(color: ProColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ProDecorations.controlRadius,
          borderSide: const BorderSide(color: ProColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ProDecorations.controlRadius,
          borderSide: const BorderSide(color: ProColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: ProDecorations.controlRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: ProDecorations.controlRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ProColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ProColors.disabled,
          disabledForegroundColor: ProColors.muted,
          elevation: 0,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: ProDecorations.controlRadius,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ProColors.primary,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          side: const BorderSide(color: ProColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: ProDecorations.controlRadius,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ProColors.primaryDark,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ProColors.navy,
          minimumSize: const Size.square(48),
          shape: const CircleBorder(),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ProColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 1,
        hoverElevation: 1,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 72,
        backgroundColor: ProColors.surface,
        indicatorColor: ProColors.primarySoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStatePropertyAll(IconThemeData(size: 24)),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: ProColors.primarySoft,
        selectedIconTheme: IconThemeData(color: ProColors.primary, size: 25),
        unselectedIconTheme: IconThemeData(color: ProColors.muted, size: 24),
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: ProColors.primaryDark,
        unselectedLabelColor: ProColors.muted,
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: ProColors.primary,
        dividerColor: ProColors.border,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: ProColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Color(0x24102A56),
        shape: RoundedRectangleBorder(
          borderRadius: ProDecorations.controlRadius,
          side: BorderSide(color: ProColors.border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ProColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: ProColors.surface,
        modalBarrierColor: Color(0x8F102A56),
        showDragHandle: true,
        dragHandleColor: Color(0xFFB8C3D1),
        dragHandleSize: Size(42, 4),
        elevation: 0,
        modalElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ProColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.navy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.ink,
          fontSize: 15,
          height: 1.45,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ProColors.navy,
        contentTextStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: const Color(0xFF9FD8FF),
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: ProDecorations.controlRadius,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ProColors.border,
        thickness: 1,
        space: 1,
      ),
      dataTableTheme: const DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(ProColors.surfaceMuted),
        headingTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.muted,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.ink,
          fontSize: 14,
        ),
        dividerThickness: 1,
        horizontalMargin: 20,
        columnSpacing: 24,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: ProColors.surfaceMuted,
        selectedColor: ProColors.primarySoft,
        disabledColor: const Color(0xFFF1F3F6),
        side: const BorderSide(color: ProColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.navy,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: ProColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: ProColors.primary,
        textColor: ProColors.ink,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minTileHeight: 56,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ProColors.navy,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        waitDuration: const Duration(milliseconds: 450),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ProColors.primary,
        linearTrackColor: ProColors.primarySoft,
        circularTrackColor: ProColors.primarySoft,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static Color _inputIconColor(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return ProColors.muted;
    if (states.contains(WidgetState.error)) return ProColors.error;
    if (states.contains(WidgetState.focused)) return ProColors.primary;
    return ProColors.muted;
  }
}

ThemeData buildProTheme() => ProTheme.light;

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
          borderRadius: BorderRadius.circular(12),
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
              fontFamily: 'Roboto',
              color: light ? Colors.white : ProColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
          Text(
            'PROFESSIONNEL',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: light ? const Color(0xFFD8E5D5) : ProColors.primary,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
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
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ProColors.border),
    ),
    child: child,
  );
}
