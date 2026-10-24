import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Brand colours that Material's [ColorScheme] has no slot for.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  final Color gold;
  final Color goldSoft;
  final Color onGold;
  final Color plumDeep;
  final Color plumBright;

  const BrandColors({
    required this.gold,
    required this.goldSoft,
    required this.onGold,
    required this.plumDeep,
    required this.plumBright,
  });

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [plumDeep, plumBright],
      );

  @override
  BrandColors copyWith({
    Color? gold,
    Color? goldSoft,
    Color? onGold,
    Color? plumDeep,
    Color? plumBright,
  }) =>
      BrandColors(
        gold: gold ?? this.gold,
        goldSoft: goldSoft ?? this.goldSoft,
        onGold: onGold ?? this.onGold,
        plumDeep: plumDeep ?? this.plumDeep,
        plumBright: plumBright ?? this.plumBright,
      );

  @override
  BrandColors lerp(BrandColors? other, double t) {
    if (other == null) return this;
    return BrandColors(
      gold: Color.lerp(gold, other.gold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      plumDeep: Color.lerp(plumDeep, other.plumDeep, t)!,
      plumBright: Color.lerp(plumBright, other.plumBright, t)!,
    );
  }
}

extension BrandTheme on BuildContext {
  BrandColors get brand => Theme.of(this).extension<BrandColors>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

abstract final class AppTheme {
  static const plum = Color(0xFF5B2A86);
  static const gold = Color(0xFFC9A227);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: plum,
      brightness: brightness,
      tertiary: isDark ? const Color(0xFFE6C55A) : const Color(0xFF8A6D00),
    );
    final brand = BrandColors(
      gold: isDark ? const Color(0xFFE6C55A) : gold,
      goldSoft: isDark ? const Color(0xFF3B3218) : const Color(0xFFFFF4D6),
      onGold: const Color(0xFF2B1F00),
      plumDeep: const Color(0xFF3A1460),
      plumBright: const Color(0xFF7B3FB0),
    );
    final radius = BorderRadius.circular(14);
    // Derive every custom text style from the platform typography so they all
    // share the same font family.
    final typography = Typography.material2021(colorScheme: scheme);
    final text = isDark ? typography.white : typography.black;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [brand],
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: text.titleLarge!.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        hintStyle: text.bodyLarge!
            .copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge!
              .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge!
              .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: text.labelLarge!
            .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
