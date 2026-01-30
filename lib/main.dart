import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          primary: const Color(0xFF38bdf8),
          onPrimary: const Color(0xFF0f172a),
          surface: const Color(0xFF0f172a),
          onSurface: const Color(0xFFf1f5f9),
          surfaceContainerHighest: const Color(0xFF1e293b),
          outline: const Color(0xFF475569),
        ),
        scaffoldBackgroundColor: const Color(0xFF0f172a),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: const Color(0xFF0f172a),
          foregroundColor: const Color(0xFFf1f5f9),
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.02,
          ),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme.copyWith(
                headlineMedium: const TextStyle(
                  color: Color(0xFFf1f5f9),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.02,
                ),
                bodyLarge: const TextStyle(
                  color: Color(0xFF94a3b8),
                  fontSize: 16,
                ),
              ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
