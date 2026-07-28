import 'package:flutter/material.dart';
import 'package:yobante/features/auth/domain/entities/user.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../injection_container.dart';
import '../../../../../core/services/token_service.dart';
import 'home_page.dart';
import 'recherche_page.dart';
import '../../../../promotions/presentation/pages/promotions_actives_page.dart';
import '../../../../commande/data/services/panier_service.dart';
import '../../../../commande/presentation/pages/panier_page.dart';
import '../../../../commande/presentation/pages/commande_page.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const green      = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const border     = Color(0xFFEDF0F7);
  static const inactive   = Color(0xFFC2C9D6);
  static const or         = Color(0xFFF5C518);
}

/// Destinations de la barre du bas, désignées par leur rôle et non par leur
/// index : la barre n'a pas la même composition pour un visiteur et pour un
/// client connecté, un index nu ne désignerait donc pas le même écran.
enum OngletClient { accueil, recherche, promotions, panier, commande }

/// Onglet réclamé depuis une page ouverte par-dessus la boutique — le menu de
/// la [BarreBoutique], par exemple, qui ramène à l'accueil ou aux catégories.
///
/// La page racine l'écoute et s'y positionne, puis remet la valeur à nul : la
/// demande est consommée une seule fois.
final ValueNotifier<OngletClient?> ongletClientDemande =
    ValueNotifier<OngletClient?>(null);

// ─── Modèle d'un item de navigation ──────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  /// Écran visé par cet item.
  final OngletClient? onglet;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.onglet,
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
  // d'historique à afficher. Pas d'onglet Connexion non plus : se connecter est
  // proposé là où c'est utile — l'en-tête de l'accueil, le panier au moment de
  // valider — et non comme une destination permanente.
  static const List<_NavItem> _navVisiteur = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
      onglet: OngletClient.accueil,
    ),
    _NavItem(
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      label: 'Rechercher',
      onglet: OngletClient.recherche,
    ),
    _NavItem(
      icon: Icons.local_offer_outlined,
      activeIcon: Icons.local_offer_rounded,
      label: 'Promotion',
      onglet: OngletClient.promotions,
    ),
    _NavItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
      label: 'Panier',
      onglet: OngletClient.panier,
    ),
  ];

  static const List<_NavItem> _navConnecte = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
      onglet: OngletClient.accueil,
    ),
    _NavItem(
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      label: 'Rechercher',
      onglet: OngletClient.recherche,
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Commande',
      onglet: OngletClient.commande,
    ),
    _NavItem(
      icon: Icons.local_offer_outlined,
      activeIcon: Icons.local_offer_rounded,
      label: 'Promotion',
      onglet: OngletClient.promotions,
    ),
    _NavItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
      label: 'Panier',
      onglet: OngletClient.panier,
    ),
  ];

  /// Déterminé depuis le token et non depuis `widget.user` : à la restauration
  /// de session, le splash ouvre cette page sans passer d'utilisateur.
  bool _estConnecte = false;

  List<_NavItem> get _navItems => _estConnecte ? _navConnecte : _navVisiteur;

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

    // Tranché dès la construction : l'utilisateur transmis par le login, sinon
    // l'état de session déjà en cache. Interroger le stockage sécurisé ici
    // aurait affiché la barre visiteur le temps de la lecture, même pour un
    // client connecté. La vérification asynchrone reste, en filet.
    _estConnecte = widget.user != null || sl<TokenService>().estConnecte;
    _construirePages();
    _verifierSession();

    _itemCtrl = List.generate(
      _navVisiteur.length > _navConnecte.length
          ? _navVisiteur.length
          : _navConnecte.length,
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

    ongletClientDemande.addListener(_surOngletDemande);
  }

  /// Se positionne sur l'onglet réclamé par une page ouverte au-dessus.
  void _surOngletDemande() {
    final onglet = ongletClientDemande.value;
    if (onglet == null || !mounted) return;
    ongletClientDemande.value = null; // demande consommée
    final index = _navItems.indexWhere((item) => item.onglet == onglet);
    // Un onglet absent de la barre courante (« Commande » chez le visiteur)
    // est ignoré plutôt que de renvoyer sur un écran arbitraire.
    if (index >= 0) _onTap(index);
  }

  @override
  void dispose() {
    ongletClientDemande.removeListener(_surOngletDemande);
    for (final ctrl in _itemCtrl) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _onTap(int index) async {
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

  /// Pastille du nombre d'articles, posée sur l'icône du panier.
  Widget _compteurPanier() {
    return Positioned(
      top: -6,
      right: -8,
      child: ListenableBuilder(
        listenable: sl<PanierService>(),
        builder: (_, __) {
          final nombre = sl<PanierService>().nombreArticles;
          if (nombre == 0) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.all(3),
            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            decoration: const BoxDecoration(
                color: _C.green, shape: BoxShape.circle),
            child: Text(
              '$nombre',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _C.or,
              ),
            ),
          );
        },
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
                // Nombre d'articles du panier, comme sur la barre supérieure :
                // le client doit retrouver son panier rempli en revenant sur
                // l'accueil, sans avoir à ouvrir l'onglet pour s'en assurer.
                if (item.onglet == OngletClient.panier) _compteurPanier(),
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