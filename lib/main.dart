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
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: AppTheme.accent,
          onPrimary: Colors.white,
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
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme.copyWith(
                headlineMedium: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  letterSpacing: 0,
                ),
                bodyLarge: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
                bodyMedium: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.surfaceVariant,
          contentTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSnackBar),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
