import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routing/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData.light().textTheme;
    final baseDarkTextTheme = ThemeData.dark().textTheme;

    return MaterialApp.router(
      title: 'AjoPay',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8E6A0),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).copyWith(
          displayLarge: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.displayLarge),
          displayMedium: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.displayMedium),
          displaySmall: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.displaySmall),
          headlineLarge: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.headlineLarge),
          headlineMedium: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.headlineMedium),
          headlineSmall: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.headlineSmall),
          titleLarge: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.titleLarge),
          titleMedium: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.titleMedium),
          titleSmall: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.titleSmall),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8E6A0),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(baseDarkTextTheme).copyWith(
          displayLarge: GoogleFonts.spaceGrotesk(textStyle: baseDarkTextTheme.displayLarge),
          displayMedium: GoogleFonts.spaceGrotesk(textStyle: baseDarkTextTheme.displayMedium),
          displaySmall: GoogleFonts.spaceGrotesk(textStyle: baseDarkTextTheme.displaySmall),
          headlineLarge: GoogleFonts.spaceGrotesk(textStyle: baseDarkTextTheme.headlineLarge),
          headlineMedium: GoogleFonts.spaceGrotesk(textStyle: baseDarkTextTheme.headlineMedium),
          headlineSmall: GoogleFonts.spaceGrotesk(textStyle: baseDarkTextTheme.headlineSmall),
          titleLarge: GoogleFonts.spaceGrotesk(textStyle: baseDarkTextTheme.titleLarge),
          titleMedium: GoogleFonts.spaceGrotesk(textStyle: baseDarkTextTheme.titleMedium),
          titleSmall: GoogleFonts.spaceGrotesk(textStyle: baseDarkTextTheme.titleSmall),
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
