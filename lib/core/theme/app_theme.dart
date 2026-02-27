import 'package:flutter/material.dart';

class GowlokColors {
  static const Color success = Color(0xFF37FD12);
  static const Color primary = Color(0xFF0000FF);
  static const Color critical = Color(0xFFFF0000);
  
  static const Color neutral100 = Color(0xFFFAFAFA);
  static const Color neutral200 = Color(0xFFF5F5F5);
  static const Color neutral300 = Color(0xFFEFEFEF);
  static const Color neutral400 = Color(0xFFE0E0E0);
  static const Color neutral500 = Color(0xFFBDBDBD);
  static const Color neutral600 = Color(0xFF888888);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);
}

class GowlokSpacing {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
}

class GowlokTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}

class GowlokTheme {
  static const double cardRadius = 12.0;
  static const double buttonRadius = 12.0;
  static const double chipRadius = 12.0;
  
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: GowlokColors.primary,
      scaffoldBackgroundColor: GowlokColors.neutral100,
      cardColor: Colors.white,
      textTheme: TextTheme(
        headlineSmall: GowlokTextStyles.headline1,
        headlineMedium: GowlokTextStyles.headline2,
        titleLarge: GowlokTextStyles.headline3,
        bodyLarge: GowlokTextStyles.bodyLarge,
        bodyMedium: GowlokTextStyles.bodyMedium,
        bodySmall: GowlokTextStyles.bodySmall,
        labelMedium: GowlokTextStyles.labelMedium,
        labelSmall: GowlokTextStyles.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GowlokTextStyles.headline3.copyWith(
          color: GowlokColors.neutral900,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          side: BorderSide(color: GowlokColors.neutral300, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GowlokColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: GowlokSpacing.md,
            vertical: GowlokSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GowlokTheme.buttonRadius),
          ),
          textStyle: GowlokTextStyles.labelMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GowlokColors.neutral200,
        disabledColor: GowlokColors.neutral300,
        selectedColor: GowlokColors.primary,
        secondarySelectedColor: GowlokColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: GowlokSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.chipRadius),
        ),
        labelStyle: GowlokTextStyles.bodySmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GowlokColors.neutral200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          borderSide: BorderSide(color: GowlokColors.neutral400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          borderSide: BorderSide(color: GowlokColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          borderSide: BorderSide(color: GowlokColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GowlokSpacing.md,
          vertical: GowlokSpacing.sm,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: GowlokColors.primary,
        unselectedItemColor: GowlokColors.neutral600,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: GowlokColors.primary,
      scaffoldBackgroundColor: GowlokColors.neutral900,
      cardColor: GowlokColors.neutral800,
      textTheme: TextTheme(
        headlineSmall: GowlokTextStyles.headline1.copyWith(
          color: GowlokColors.neutral100,
        ),
        headlineMedium: GowlokTextStyles.headline2.copyWith(
          color: GowlokColors.neutral100,
        ),
        titleLarge: GowlokTextStyles.headline3.copyWith(
          color: GowlokColors.neutral100,
        ),
        bodyLarge: GowlokTextStyles.bodyLarge.copyWith(
          color: GowlokColors.neutral200,
        ),
        bodyMedium: GowlokTextStyles.bodyMedium.copyWith(
          color: GowlokColors.neutral300,
        ),
        bodySmall: GowlokTextStyles.bodySmall.copyWith(
          color: GowlokColors.neutral500,
        ),
        labelMedium: GowlokTextStyles.labelMedium.copyWith(
          color: GowlokColors.neutral100,
        ),
        labelSmall: GowlokTextStyles.labelSmall.copyWith(
          color: GowlokColors.neutral200,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: GowlokColors.neutral800,
        surfaceTintColor: GowlokColors.neutral800,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GowlokTextStyles.headline3.copyWith(
          color: GowlokColors.neutral100,
        ),
      ),
      cardTheme: CardThemeData(
        color: GowlokColors.neutral800,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          side: BorderSide(color: GowlokColors.neutral700, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GowlokColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: GowlokSpacing.md,
            vertical: GowlokSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GowlokTheme.buttonRadius),
          ),
          textStyle: GowlokTextStyles.labelMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GowlokColors.neutral700,
        disabledColor: GowlokColors.neutral600,
        selectedColor: GowlokColors.primary,
        secondarySelectedColor: GowlokColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: GowlokSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.chipRadius),
        ),
        labelStyle: GowlokTextStyles.bodySmall.copyWith(
          color: GowlokColors.neutral100,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GowlokColors.neutral700,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          borderSide: BorderSide(color: GowlokColors.neutral600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          borderSide: BorderSide(color: GowlokColors.neutral700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          borderSide: BorderSide(color: GowlokColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GowlokSpacing.md,
          vertical: GowlokSpacing.sm,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: GowlokColors.neutral800,
        selectedItemColor: GowlokColors.primary,
        unselectedItemColor: GowlokColors.neutral600,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
