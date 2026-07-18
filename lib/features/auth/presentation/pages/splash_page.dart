import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';

// ─── Palette Yobante Boutique ───────────────────────────────────────────────────
class _C {
  static const blue       = Color(0xFF163A9E); // Bleu principal
  static const blueDark   = Color(0xFF0F2A78); // Bleu profond (fond dégradé)
  static const gold       = Color(0xFFF5C518); // Jaune / or accent
  static const white      = Color(0xFFFFFFFF);
  static const ink        = Color(0xFF1A1A1A); // Texte sur fond blanc
  static const sub        = Color(0xFF6B7280); // Texte secondaire
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  late AnimationController _scaleCtrl;
  late Animation<double>   _scaleAnim;

  late AnimationController _taglineCtrl;
  late Animation<double>   _taglineFade;
  late Animation<Offset>   _taglineSlide;

  late AnimationController _loaderCtrl;
  late Animation<double>   _loaderFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkAuthStatus();
  }

  void _initAnimations() {
    // Logo fade + scale
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack),
    );

    // Tagline apparaît après le logo
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineFade  = CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut);
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOutCubic));

    // Loader apparaît en dernier
    _loaderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loaderFade = CurvedAnimation(parent: _loaderCtrl, curve: Curves.easeOut);

    // Cascade d'animations
    _fadeCtrl.forward();
    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _taglineCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _loaderCtrl.forward();
    });
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 4500));

    final storage = sl<FlutterSecureStorage>();
    String? token;

    try {
      token = await storage.read(key: 'jwt_token');
      debugPrint('🔑 Token: $token');
    } catch (e) {
      debugPrint('Erreur token: $e');
    }

    if (!mounted) return;

    // Session valide → on ouvre l'interface correspondant au rôle porté par le
    // token. Sinon → onboarding : le visiteur peut consulter la boutique sans
    // compte et ne se connectera que pour valider sa commande.
    if (token != null && token.isNotEmpty) {
      try {
        if (!Jwt.isExpired(token)) {
          final payload = Jwt.parseJwt(token);
          Navigator.of(context).pushReplacementNamed(
            AppRouter.routeSelonRole(payload['role']?.toString()),
          );
          return;
        }
      } catch (e) {
        debugPrint('Erreur décodage token: $e');
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.onboardingRoute);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _taglineCtrl.dispose();
    _loaderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.white,
      body: Container(
        color: _C.white,
        child: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Stack(
                children: [
                  // Contenu centré
                  Center(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLogo(),
                            const SizedBox(height: 22),
                            _buildTagline(),
                            const SizedBox(height: 48),
                            _buildLoader(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Version en bas
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: _buildVersion(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fond décoratif (halos dorés diffus) ────────────────────────────────────
  Widget _buildBackground() {
    return Stack(
      children: [
        // Halo doré haut-gauche
        Positioned(
          top: -80,
          left: -60,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 2000),
            builder: (_, v, __) => Transform.translate(
              offset: Offset(18 * v, 12 * v),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _C.gold.withOpacity(0.14),
                      _C.gold.withOpacity(0.0),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),

        // Halo doré bas-droit
        Positioned(
          bottom: -100,
          right: -70,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 2500),
            builder: (_, v, __) => Transform.translate(
              offset: Offset(-20 * v, -18 * v),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _C.gold.withOpacity(0.10),
                      _C.gold.withOpacity(0.0),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),

        // Motif de points doré (coin haut-droit)
        Positioned(
          top: 60,
          right: 20,
          child: Opacity(
            opacity: 0.14,
            child: SizedBox(
              width: 80,
              height: 80,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 25,
                itemBuilder: (_, __) => Container(
                  decoration: const BoxDecoration(
                    color: _C.gold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Logo Yobante Boutique (fond blanc) ─────────────────────────────────────
  Widget _buildLogo() {
    return Image.asset(
      'assets/images/Logo Yobante Boutique - fond blanc.png',
      width: 250,
      fit: BoxFit.contain,
    );
  }

  // ── Tagline animée ─────────────────────────────────────────────────────────
  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineFade,
      child: SlideTransition(
        position: _taglineSlide,
        child: Column(
          children: [
            // Badge statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _C.blue.withOpacity(0.05),
                border: Border.all(color: _C.gold.withOpacity(0.7), width: 1.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _C.gold.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _C.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ]),
                  const SizedBox(width: 8),
                  Text(
                    'Votre boutique en ligne',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Parcourez, choisissez et commandez\nvos articles en toute simplicité.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: _C.sub,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Indicateur de chargement ───────────────────────────────────────────────
  Widget _buildLoader() {
    return FadeTransition(
      opacity: _loaderFade,
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              backgroundColor: _C.blue.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(_C.blue),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Préparation en cours…',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _C.sub,
            ),
          ),
        ],
      ),
    );
  }

  // ── Version ────────────────────────────────────────────────────────────────
  Widget _buildVersion() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: _C.blue.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.blue.withOpacity(0.12), width: 1),
        ),
        child: Text(
          'v1.0.0  •  Yobante Boutique',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _C.blue,
          ),
        ),
      ),
    );
  }
}
