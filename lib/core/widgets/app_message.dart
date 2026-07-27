import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppMessage {
  static const _green = Color(0xFF163A9E);
  static const _red = Color(0xFFEF4444);
  static const _yellow = Color(0xFFFB923C);
  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF1A1A1A);

  /// Affiche un message de succès
  static void success(BuildContext context, String message) {
    _show(context, message, _green, Icons.check_circle_rounded);
  }

  /// Affiche un message d'erreur
  static void error(BuildContext context, String message) {
    _show(context, message, _red, Icons.error_rounded);
  }

  /// Affiche un message d'avertissement
  static void warning(BuildContext context, String message) {
    _show(context, message, _yellow, Icons.warning_rounded);
  }

  /// Affiche un message d'info
  static void info(BuildContext context, String message) {
    _show(context, message, _green, Icons.info_rounded);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: _white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _white,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }
}
