import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_compressor/app_theme.dart';
import 'package:image_compressor/home_page.dart';

void main() {
  runApp(const ImageCompressorApp());
}

class ImageCompressorApp extends StatelessWidget {
  const ImageCompressorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Compressor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: AppTheme.accent,
          onPrimary: AppTheme.background,
          surface: AppTheme.background,
          onSurface: AppTheme.textPrimary,
          surfaceContainerHighest: AppTheme.surface,
          outline: AppTheme.outline,
        ),
        scaffoldBackgroundColor: AppTheme.background,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppTheme.background,
          foregroundColor: AppTheme.textPrimary,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.02,
          ),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme.copyWith(
                headlineMedium: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.02,
                ),
                bodyLarge: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSnackBar),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
