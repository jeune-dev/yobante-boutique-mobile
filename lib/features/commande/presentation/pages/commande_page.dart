import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/token_service.dart';
import 'mes_commandes_page.dart';

class _C {
  static const green      = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const border     = Color(0xFFEDF0F7);
  static const sub        = Color(0xFF6B7280);
}

/// Onglet « Commande » de la barre de navigation.
/// - Invité (non connecté)  → invitation à se connecter.
/// - Client connecté        → liste de ses commandes (backend).
class CommandePage extends StatefulWidget {
  const CommandePage({super.key});

  @override
  State<CommandePage> createState() => _CommandePageState();
}

class _CommandePageState extends State<CommandePage> {
  final _tokenService = sl<TokenService>();
  bool? _authenticated; // null = en cours de vérification
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _check();
    _sub = _tokenService.authChanges.listen((auth) {
      if (mounted) setState(() => _authenticated = auth);
    });
  }

  Future<void> _check() async {
    final auth = await _tokenService.isAuthenticated;
    if (mounted) setState(() => _authenticated = auth);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated == null) {
      return const Scaffold(
        backgroundColor: _C.bg,
        body: Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5)),
      );
    }
    if (_authenticated == true) {
      return const MesCommandesPage();
    }
    return _buildInvite();
  }

  Widget _buildInvite() {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Center(
                child: Text('Mes commandes',
                    style: GoogleFonts.sora(
                        fontSize: 18, fontWeight: FontWeight.w800, color: _C.black)),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
                    decoration: BoxDecoration(
                      color: _C.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _C.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: _C.greenLight,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: _C.green, size: 34),
                        ),
                        const SizedBox(height: 18),
                        Text('Suivez vos commandes',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.sora(
                                fontSize: 18, fontWeight: FontWeight.w800, color: _C.black)),
                        const SizedBox(height: 8),
                        Text(
                          'Connectez-vous pour retrouver l\'historique de vos '
                          'commandes, suivre leur état et consulter les détails.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(fontSize: 13.5, height: 1.5, color: _C.sub),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed(AppRouter.loginRoute),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: _C.green,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text('Se connecter',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 15, fontWeight: FontWeight.w700, color: _C.white)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed(AppRouter.registerRoute),
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: 'Pas encore de compte ? ',
                                style: GoogleFonts.dmSans(fontSize: 13, color: _C.sub),
                              ),
                              TextSpan(
                                text: 'Créer un compte',
                                style: GoogleFonts.dmSans(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: _C.green),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
