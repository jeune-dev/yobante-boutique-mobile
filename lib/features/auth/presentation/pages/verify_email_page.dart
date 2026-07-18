import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/datasources/auth_remote_datasource.dart';

class _C {
  static const green      = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const sub        = Color(0xFF6B7280);
  static const border     = Color(0xFFDDE3EF);
}

/// Saisie du code reçu par email après inscription (GET /auth/verify-email).
/// Non bloquant : l'utilisateur peut passer cette étape et se connecter quand
/// même (le backend n'exige pas la vérification pour le login).
class VerifyEmailPage extends StatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await sl<AuthRemoteDataSource>().verifyEmail(widget.email, code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Email vérifié ✅'),
        backgroundColor: _C.green,
        behavior: SnackBarBehavior.floating,
      ));
      _allerLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _allerLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        foregroundColor: _C.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: _C.greenLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: _C.green, size: 30),
              ),
              const SizedBox(height: 20),
              Text('Vérifiez votre email',
                  style: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w800, color: _C.black)),
              const SizedBox(height: 8),
              Text(
                'Un code de vérification a été envoyé à\n${widget.email}. Saisissez-le ci-dessous.',
                style: GoogleFonts.dmSans(fontSize: 14, color: _C.sub, height: 1.5),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verify(),
                style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 4, color: _C.black),
                decoration: InputDecoration(
                  hintText: 'Code',
                  hintStyle: GoogleFonts.dmSans(color: _C.sub, letterSpacing: 0),
                  filled: true,
                  fillColor: _C.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _C.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _C.green, width: 1.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _C.border),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.black,
                    foregroundColor: _C.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Vérifier', style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : _allerLogin,
                  child: Text('Plus tard',
                      style: GoogleFonts.dmSans(color: _C.sub, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
