import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';

// ─── Palette Yobante Boutique ───────────────────────────────────────────────────
class _C {
  static const blue       = Color(0xFF163A9E); // Bleu principal
  static const blueLight  = Color(0xFFEAEEF9); // Bleu très clair (fonds)
  static const blueBorder = Color(0xFFC3D0EE); // Bordure bleutée
  static const gold       = Color(0xFFF5C518); // Jaune / or accent
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const sub        = Color(0xFF6B7280);
}

class _Slide {
  final IconData icon;
  final IconData badge1;
  final IconData badge2;
  final String title1;
  final String title2;
  final String subtitle;
  const _Slide({
    required this.icon,
    required this.badge1,
    required this.badge2,
    required this.title1,
    required this.title2,
    required this.subtitle,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_Slide> _slides = [
    _Slide(
      icon: Icons.storefront_rounded,
      badge1: Icons.local_offer_rounded,
      badge2: Icons.verified_rounded,
      title1: 'Bienvenue chez ',
      title2: 'Yobante Boutique',
      subtitle:
          'Parcourez librement notre catalogue et découvrez tous nos articles, sans même créer de compte.',
    ),
    _Slide(
      icon: Icons.add_shopping_cart_rounded,
      badge1: Icons.favorite_rounded,
      badge2: Icons.check_circle_rounded,
      title1: 'Remplissez votre ',
      title2: 'panier',
      subtitle:
          'Ajoutez vos articles au panier et ajustez les quantités en quelques secondes, à votre rythme.',
    ),
    _Slide(
      icon: Icons.local_shipping_rounded,
      badge1: Icons.schedule_rounded,
      badge2: Icons.lock_rounded,
      title1: 'Connectez-vous et ',
      title2: 'commandez',
      subtitle:
          'Créez un compte pour valider votre commande, puis choisissez la livraison ou le retrait en boutique.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _terminer() async {
    try {
      await sl<SharedPreferences>().setBool('onboarding_seen', true);
    } catch (_) {/* si l'écriture échoue, l'onboarding se remontrera — sans gravité */}
    if (!mounted) return;
    // Yobante Boutique = app client : on entre directement dans la boutique.
    // Le client consulte et remplit son panier sans compte ; la connexion n'est
    // demandée qu'au moment de valider la commande.
    Navigator.of(context).pushReplacementNamed(AppRouter.acheteurRoute);
  }

  void _suivant() {
    if (_index >= _slides.length - 1) {
      _terminer();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dernier = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                // ── Barre du haut : Passer ────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: dernier ? 0 : 1,
                      child: TextButton(
                        onPressed: dernier ? null : _terminer,
                        child: Text('Passer',
                            style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _C.sub)),
                      ),
                    ),
                  ),
                ),

                // ── Slides ────────────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => _buildSlide(_slides[i]),
                  ),
                ),

                // ── Bas : indicateur + bouton ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Row(
                    children: [
                      _buildDots(),
                      const Spacer(),
                      _buildBouton(dernier),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Décor de fond (cercles bleus diffus, cohérent avec le reste de l'app) ──
  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -90, right: -70,
          child: Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.blue.withOpacity(0.10),
                _C.blue.withOpacity(0.0),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -80, left: -60,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.gold.withOpacity(0.10),
                _C.gold.withOpacity(0.0),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Un slide : visuel (icônes/formes, pas de personnage) + textes ──────────
  Widget _buildSlide(_Slide s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildVisual(s)),
          const SizedBox(height: 44),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: s.title1,
                style: GoogleFonts.sora(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _C.black,
                    height: 1.2,
                    letterSpacing: -0.6),
              ),
              TextSpan(
                text: s.title2,
                style: GoogleFonts.sora(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _C.blue,
                    height: 1.2,
                    letterSpacing: -0.6),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Text(
            s.subtitle,
            style: GoogleFonts.dmSans(
                fontSize: 14.5, color: _C.sub, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── Composition graphique : gros disque bleu + icône + 2 badges flottants ──
  Widget _buildVisual(_Slide s) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Halo externe
          Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.blue.withOpacity(0.06),
            ),
          ),
          // Disque principal
          Container(
            width: 176, height: 176,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.blueLight,
              border: Border.all(color: _C.blueBorder, width: 1.4),
            ),
            child: Icon(s.icon, size: 84, color: _C.blue),
          ),
          // Badge haut-droit (accent doré)
          Positioned(
            top: 18, right: 8,
            child: _badge(s.badge1, _C.gold, _C.black),
          ),
          // Badge bas-gauche
          Positioned(
            bottom: 22, left: 4,
            child: _badge(s.badge2, _C.white, _C.blue, bordered: true),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, Color bg, Color fg, {bool bordered = false}) {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: bordered ? Border.all(color: _C.blueBorder, width: 1.4) : null,
        boxShadow: [
          BoxShadow(
            color: _C.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 22, color: fg),
    );
  }

  // ── Indicateur de progression (points) ────────────────────────────────────
  Widget _buildDots() {
    return Row(
      children: List.generate(_slides.length, (i) {
        final actif = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 6),
          width: actif ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: actif ? _C.blue : _C.blueBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ── Bouton Suivant / Commencer ─────────────────────────────────────────────
  Widget _buildBouton(bool dernier) {
    return GestureDetector(
      onTap: _suivant,
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: dernier ? 26 : 0),
        width: dernier ? null : 56,
        decoration: BoxDecoration(
          color: _C.blue,
          borderRadius: BorderRadius.circular(dernier ? 18 : 28),
          boxShadow: [
            BoxShadow(
              color: _C.blue.withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (dernier)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text('Commencer',
                    style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _C.white)),
              ),
            Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(
                color: _C.gold,
                shape: BoxShape.circle,
              ),
              child: Icon(
                dernier ? Icons.check_rounded : Icons.arrow_forward_rounded,
                color: _C.black,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
