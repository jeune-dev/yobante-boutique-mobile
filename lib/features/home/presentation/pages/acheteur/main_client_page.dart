import 'package:flutter/material.dart';
import 'package:yobante/features/auth/domain/entities/user.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../injection_container.dart';
import '../../../../../core/routes/app_router.dart';
import '../../../../../core/services/token_service.dart';
import 'home_page.dart';
import 'recherche_page.dart';
import '../../../../promotions/presentation/pages/promotions_actives_page.dart';
import '../../../../commande/presentation/pages/panier_page.dart';
import '../../../../commande/presentation/pages/commande_page.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const green      = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const border     = Color(0xFFEDF0F7);
  static const label      = Color(0xFF9AA3B2);
  static const inactive   = Color(0xFFC2C9D6);
}

// ─── Modèle d'un item de navigation ──────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool hasNotif;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.hasNotif = false,
  });
}

class MainAcheteurPage extends StatefulWidget {
  final User? user;
  const MainAcheteurPage({super.key, this.user});

  @override
  State<MainAcheteurPage> createState() => _MainAcheteurPageState();
}

class _MainAcheteurPageState extends State<MainAcheteurPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // Animations par item
  late List<AnimationController> _itemCtrl;
  late List<Animation<double>>   _itemScale;
  late List<Animation<double>>   _labelFade;

  // Navigation du visiteur : pas d'onglet Commande — sans compte il n'y a pas
  // d'historique à afficher. Le dernier item mène à la connexion au lieu de
  // changer d'onglet.
  static const List<_NavItem> _navVisiteur = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Accueil'),
    _NavItem(icon: Icons.search_rounded, activeIcon: Icons.search_rounded, label: 'Rechercher'),
    _NavItem(
      icon: Icons.local_offer_outlined,
      activeIcon: Icons.local_offer_rounded,
      label: 'Promotion',
    ),
    _NavItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
      label: 'Panier',
    ),
    _NavItem(icon: Icons.login_rounded, activeIcon: Icons.login_rounded, label: 'Connexion'),
  ];

  static const List<_NavItem> _navConnecte = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Accueil'),
    _NavItem(icon: Icons.search_rounded, activeIcon: Icons.search_rounded, label: 'Rechercher'),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Commande',
    ),
    _NavItem(
      icon: Icons.local_offer_outlined,
      activeIcon: Icons.local_offer_rounded,
      label: 'Promotion',
    ),
    _NavItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
      label: 'Panier',
    ),
  ];

  /// Déterminé depuis le token et non depuis `widget.user` : à la restauration
  /// de session, le splash ouvre cette page sans passer d'utilisateur.
  bool _estConnecte = false;

  List<_NavItem> get _navItems => _estConnecte ? _navConnecte : _navVisiteur;

  /// Index de l'item « Connexion » chez le visiteur : il déclenche une
  /// navigation au lieu d'afficher une page.
  int get _indexConnexion => _navVisiteur.length - 1;

  late List<Widget> _pages;

  void _construirePages() {
    _pages = _estConnecte
        ? [
            HomePage(user: widget.user),
            const RechercheGlobalePage(),
            const CommandePage(),
            const PromotionsActivesPage(),
            const PanierPage(),
          ]
        : [
            HomePage(user: widget.user),
            const RechercheGlobalePage(),
            const PromotionsActivesPage(),
            const PanierPage(),
            // Jamais affichée : l'item « Connexion » navigue.
            const SizedBox.shrink(),
          ];
  }

  Future<void> _verifierSession() async {
    final connecte = await sl<TokenService>().isAuthenticated;
    if (!mounted || connecte == _estConnecte) return;
    // La barre change de composition : on repart de l'accueil et on remet les
    // animations à plat, sinon l'item précédemment actif resterait mis en avant.
    _itemCtrl[_selectedIndex].reverse();
    _itemCtrl[0].forward();
    setState(() {
      _estConnecte = connecte;
      _selectedIndex = 0;
      _construirePages();
    });
  }

  @override
  void initState() {
    super.initState();

    // L'utilisateur transmis par le login suffit à trancher immédiatement ;
    // sinon on interroge le token, ce qui couvre la restauration de session.
    _estConnecte = widget.user != null;
    _construirePages();
    _verifierSession();

    _itemCtrl = List.generate(
      _navItems.length,
          (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 280),
      ),
    );

    _itemScale = _itemCtrl.map((ctrl) {
      return Tween<double>(begin: 1.0, end: 1.18).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack),
      );
    }).toList();

    _labelFade = _itemCtrl.map((ctrl) {
      return CurvedAnimation(parent: ctrl, curve: Curves.easeOut);
    }).toList();

    // Activer le premier tab au démarrage
    _itemCtrl[0].forward();
  }

  @override
  void dispose() {
    for (final ctrl in _itemCtrl) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _onTap(int index) async {
    // Chez le visiteur, « Connexion » ouvre l'écran de login. Au retour, la
    // session est réévaluée : si la connexion a réussi, la barre bascule sur
    // la navigation du client connecté.
    if (!_estConnecte && index == _indexConnexion) {
      await Navigator.of(context).pushNamed(AppRouter.loginRoute);
      await _verifierSession();
      return;
    }
    if (_selectedIndex == index) return;
    _itemCtrl[_selectedIndex].reverse();
    _itemCtrl[index].forward();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBody: false, // nav bar opaque : le contenu s'arrête au-dessus d'elle
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  // ── Barre de navigation custom ─────────────────────────────────────────────
  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        border: Border(
          top: BorderSide(color: _C.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navItems.length,
                  (i) => _buildNavItem(i),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item     = _navItems[index];
    final selected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 18 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? _C.greenLight : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône avec badge notif si besoin
            Stack(
              clipBehavior: Clip.none,
              children: [
                ScaleTransition(
                  scale: _itemScale[index],
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 22,
                    color: selected ? _C.green : _C.inactive,
                  ),
                ),
                // Badge notification orange
                if (item.hasNotif && !selected)
                  Positioned(
                    top: -2,
                    right: -3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            // Label animé (visible uniquement si sélectionné)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                padding: const EdgeInsets.only(left: 7),
                child: FadeTransition(
                  opacity: _labelFade[index],
                  child: Text(
                    item.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.green,
                    ),
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}