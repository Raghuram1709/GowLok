import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GowlokPageTransitionsBuilder extends PageTransitionsBuilder {
  const GowlokPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Enter transition: Fade in + Slide up from bottom
    final enterTween = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
    
    // Exit transition (when pushing another page on top): Scale down + Fade out
    final exitScaleTween = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut));
        
    final exitFadeTween = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut));

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: enterTween,
        child: FadeTransition(
          opacity: exitFadeTween,
          child: ScaleTransition(
            scale: exitScaleTween,
            child: child,
          ),
        ),
      ),
    );
  }
}

class GowlokColors {
  // Brand Colors
  static const Color primary = Color(0xFF0F62FE); // Deep vibrant blue
  static const Color secondary = Color(0xFF393939); // Deep neutral
  
  // Neutral Colors Light
  static const Color neutral100 = Color(0xFFF4F4F4);
  static const Color neutral200 = Color(0xFFE0E0E0);
  static const Color neutral300 = Color(0xFFC6C6C6);
  static const Color neutral400 = Color(0xFFA8A8A8);
  
  // Neutral Colors Dark
  static const Color neutral500 = Color(0xFF8D8D8D);
  static const Color neutral600 = Color(0xFF6F6F6F);
  static const Color neutral700 = Color(0xFF525252);
  static const Color neutral800 = Color(0xFF393939);
  static const Color neutral900 = Color(0xFF262626);
  
  // Semantic Colors
  static const Color success = Color(0xFF198038); // Deep green
  static const Color error = Color(0xFFDA1E28); // Deep red
  static const Color warning = Color(0xFFF1C21B); // Gold/Yellow
  static const Color info = Color(0xFF0043CE); // Info blue
  
  // Surface Colors
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF161616); // True deep dark
  
  // Farm Section Specific Colors
  static const Color farmHeaderStart = Color(0xFF0F62FE);
  static const Color farmHeaderEnd = Color(0xFF0043CE);
  
  // Quick Check Section Colors
  static const Color checkCardBgLight = Color(0xFFF8F9FA);
  static const Color checkCardBgDark = Color(0xFF262626);
  static const Color checkIconBgLight = Color(0xFFEDF5FF);
  static const Color checkIconBgDark = Color(0xFF001141);
  
  // Common Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF0043CE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF0E6027)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient checkHeaderGradient = LinearGradient(
    colors: [Color(0xFF8A3FFC), Color(0xFF6929C4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Color critical = error; // Restored for backward compatibility
}

class GowlokSpacing {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
}

class GowlokTextStyles {
  static final TextStyle headline1 = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );
  
  static final TextStyle headline2 = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );
  
  static final TextStyle headline3 = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  
  static final TextStyle bodyLarge = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static final TextStyle bodyMedium = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  
  static final TextStyle bodySmall = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  
  static final TextStyle labelMedium = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  
  static final TextStyle labelSmall = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w700,
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
      scaffoldBackgroundColor: GowlokColors.neutral100, // Light gray for deeper contrast
      cardColor: Colors.white,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: GowlokPageTransitionsBuilder(),
          TargetPlatform.iOS: GowlokPageTransitionsBuilder(),
        },
      ),
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GowlokTextStyles.headline3.copyWith(
          color: GowlokColors.neutral900,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 8, // Increased elevation for a floating premium feel
        shadowColor: Colors.black.withOpacity(0.08), // Soft premium shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          side: BorderSide(color: GowlokColors.neutral200, width: 1.5), // Softer, thicker border
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GowlokColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: GowlokColors.primary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(
            horizontal: GowlokSpacing.lg,
            vertical: GowlokSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GowlokTheme.buttonRadius),
          ),
          textStyle: GowlokTextStyles.labelMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GowlokColors.primary.withOpacity(0.08), // Primary tint
        disabledColor: GowlokColors.neutral200,
        selectedColor: GowlokColors.primary,
        secondarySelectedColor: GowlokColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: GowlokSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.chipRadius),
          side: const BorderSide(color: Colors.transparent),
        ),
        labelStyle: GowlokTextStyles.bodySmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          borderSide: BorderSide(color: GowlokColors.neutral300),
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
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: GowlokColors.primary,
        unselectedItemColor: GowlokColors.neutral600,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: GowlokColors.primary,
      scaffoldBackgroundColor: const Color(0xFF121212), // Deep pure dark
      cardColor: const Color(0xFF1E1E1E), // Elevated dark surface
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: GowlokPageTransitionsBuilder(),
          TargetPlatform.iOS: GowlokPageTransitionsBuilder(),
        },
      ),
      textTheme: TextTheme(
        headlineSmall: GowlokTextStyles.headline1.copyWith(color: Colors.white),
        headlineMedium: GowlokTextStyles.headline2.copyWith(color: Colors.white),
        titleLarge: GowlokTextStyles.headline3.copyWith(color: Colors.white),
        bodyLarge: GowlokTextStyles.bodyLarge.copyWith(color: GowlokColors.neutral200),
        bodyMedium: GowlokTextStyles.bodyMedium.copyWith(color: GowlokColors.neutral300),
        bodySmall: GowlokTextStyles.bodySmall.copyWith(color: GowlokColors.neutral400),
        labelMedium: GowlokTextStyles.labelMedium.copyWith(color: Colors.white),
        labelSmall: GowlokTextStyles.labelSmall.copyWith(color: GowlokColors.neutral200),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GowlokTextStyles.headline3.copyWith(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1), // Subtle light stroke
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GowlokColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: GowlokColors.primary.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(
            horizontal: GowlokSpacing.lg,
            vertical: GowlokSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GowlokTheme.buttonRadius),
          ),
          textStyle: GowlokTextStyles.labelMedium,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GowlokColors.primary.withOpacity(0.15), // Highly visible primary tint
        disabledColor: GowlokColors.neutral800,
        selectedColor: GowlokColors.primary,
        secondarySelectedColor: GowlokColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: GowlokSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.chipRadius),
          side: const BorderSide(color: Colors.transparent),
        ),
        labelStyle: GowlokTextStyles.bodySmall.copyWith(color: GowlokColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
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
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: GowlokColors.primary,
        unselectedItemColor: GowlokColors.neutral500,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
    );
  }
}
