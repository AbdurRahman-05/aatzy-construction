import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide "Bento" theme: charcoal base, brand teal accent, big rounded surfaces.
/// Keep these values in sync with `Bento` in core/widgets/bento.dart.
class AppTheme {
  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------
  static const Color teal = Color(0xFF0D9488);
  static const Color tealDeep = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFF2DD4BF);
  static const Color tealSoft = Color(0xFFCCFBF1);
  static const Color ink = Color(0xFF111318);

  // Backwards-compatible names used across the app (they now all mean "brand teal")
  static const Color primaryOrange = tealDeep;
  static const Color primaryOrangeDark = Color(0xFF115E59);
  static const Color primaryTeal = tealDeep;
  static const Color secondaryTeal = teal;
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color accentGreen = Color(0xFF16A34A);

  // Surfaces & text
  static const Color backgroundNeutral = Color(0xFFF6F5F2);
  static const Color backgroundWhite = backgroundNeutral;
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color textDark = ink;
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFECEAE6);

  static const Color darkBackground = Color(0xFF0E1015);
  static const Color darkSurface = Color(0xFF181B22);
  static const Color darkSurfaceAlt = Color(0xFF22262F);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), tealDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = primaryGradient;

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF242833), ink],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const double radiusLg = 24;
  static const double radiusMd = 16;

  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: SmoothPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: SmoothPageTransitionsBuilder(),
    },
  );

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? teal : tealDeep;
    final surface = dark ? darkSurface : cardSurface;
    final surfaceAlt = dark ? darkSurfaceAlt : backgroundNeutral;
    final onSurface = dark ? Colors.white : ink;
    final muted = dark ? const Color(0xFF9AA1AD) : textSecondary;
    final border = dark ? Colors.white.withValues(alpha: 0.08) : borderColor;

    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: dark ? tealLight : teal,
      surface: surface,
      onSurface: onSurface,
      error: error,
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(bodyColor: onSurface, displayColor: onSurface);

    final textTheme = baseText.copyWith(
      headlineLarge: baseText.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
      headlineMedium: baseText.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
      headlineSmall: baseText.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );

    final buttonText = GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15);
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd));

    OutlineInputBorder inputBorder(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      pageTransitionsTheme: _pageTransitions,
      scaffoldBackgroundColor: dark ? darkBackground : backgroundNeutral,
      canvasColor: dark ? darkBackground : backgroundNeutral,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
        floatingLabelStyle: TextStyle(color: primary, fontWeight: FontWeight.w700),
        hintStyle: TextStyle(color: muted.withValues(alpha: 0.8)),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(primary, 1.8),
        errorBorder: inputBorder(error, 1.2),
        focusedErrorBorder: inputBorder(error, 1.8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: surfaceAlt,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          shape: rounded,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          shape: rounded,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          shape: rounded,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? tealLight : tealDeep,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
          shape: rounded,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: dark ? teal.withValues(alpha: 0.25) : tealSoft,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: onSurface),
        checkmarkColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: dark ? tealLight : tealDeep,
        unselectedLabelColor: muted,
        indicatorColor: primary,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: onSurface),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? darkSurfaceAlt : ink,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceAlt,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : null),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.transparent : null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : null),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: teal.withValues(alpha: 0.25),
        selectionHandleColor: primary,
      ),
    );
  }
}

class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}
