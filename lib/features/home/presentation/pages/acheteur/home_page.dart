import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yobante/features/auth/domain/entities/user.dart';
import '../../bloc/produit_bloc.dart';
import '../../bloc/produit_event.dart';
import '../../bloc/produit_state.dart';
import '../../../data/repositories/produit_repository_impl.dart';
import '../../../data/datasources/produit_remote_datasource.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/models/boutique_model.dart';
import '../../../data/models/rayon_model.dart';
import '../../../../../features/promotions/data/models/promo_groupee_model.dart';
import '../../../../../core/services/token_service.dart';
import '../../../../../injection_container.dart';
import '../../../../../core/services/whatsapp_service.dart';
import '../../../../promotions/presentation/bloc/promotions_bloc.dart';
import '../../../../promotions/presentation/bloc/promotions_event.dart';
import '../../../../promotions/presentation/bloc/promotions_state.dart';
import '../../../../promotions/presentation/pages/promotions_actives_page.dart';
import '../../../../promotions/data/datasources/promotions_remote_datasource.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../favoris/data/datasources/favoris_remote_datasource.dart';
import '../../../../commande/data/datasources/commande_remote_datasource.dart';
import '../../../../commande/data/services/panier_service.dart';
import '../../../../commande/presentation/pages/panier_page.dart';
import 'boutiques_page.dart';
import 'produit_detail_page.dart';
import 'produit_page.dart';
import 'categorie_produits_page.dart';
import 'rayon_produits_page.dart';
import 'profil_page.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../auth/presentation/pages/login_page.dart';
import '../../../../compte/presentation/bloc/compte_bloc.dart';
import '../../../../compte/presentation/bloc/compte_event.dart';
import '../../../../compte/presentation/bloc/compte_state.dart';
import 'dart:async';


class _C {
  static const green       = Color(0xFF163A9E);
  static const greenLight  = Color(0xFFEAEEF9);
  static const black       = Color(0xFF1A1A1A);
  static const white       = Color(0xFFFFFFFF);
  static const bg          = Color(0xFFF5F7FB);
  static const surface     = Color(0xFFF7F9FC);
  static const border      = Color(0xFFEDF0F7);
  static const label       = Color(0xFF9AA3B2);
  static const sub         = Color(0xFF6B7280);
  static const orange      = Color(0xFFFF5722);
  static const amber       = Color(0xFFFF9800);
  static const whatsapp    = Color(0xFF25D366);
}

// ── Modèle d'une carte publicitaire "À ne pas manquer" ──────────────────────
class _Ad {
  final String tag;
  final String big;
  final String sub;
  const _Ad({required this.tag, required this.big, required this.sub});
}

// ── Modèle d'un rayon (catégorie) ───────────────────────────────────────────
class _Rayon {
  final String label;
  final IconData icon;
  const _Rayon(this.label, this.icon);
}

class HomePage extends StatefulWidget {
  final User? user;
  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _loading     = false;
  int  _nbCommandes = 0;
  int  _nbFavoris   = 0;
  int  _nbPanier    = 0;

  // Utilisateur : soit passé en argument, soit chargé via /account/me si absent
  final CompteBloc _compteBloc = sl<CompteBloc>();
  User? _liveUser;
  StreamSubscription? _compteSub;
  User? get _user => widget.user ?? _liveUser;

  List<BoutiqueModel> _boutiques      = [];
  bool                _boutiquesLoad  = false;
  String?             _boutiquesError;

  // Découverte (endpoints backend jusque-là inexploités)
  List<ProduitModel>  _tendances = [];
  List<BoutiqueModel> _nouvelles = [];

  // API : rayons, bannières, promotions groupées
  List<RayonModel>  _rayonsApi        = [];
  List<dynamic>     _banniersList     = [];
  PromoGroupeeModel? _promoGroupee;

  late AnimationController _headerCtrl;
  late Animation<double>   _headerFade;
  late Animation<Offset>   _headerSlide;

  late AnimationController _contentCtrl;
  late Animation<double>   _contentFade;

  ProduitRemoteDataSource? _dataSource;
  ProduitBloc?             _produitBloc;
  late final PromotionsBloc _promotionsBloc;

  // Carrousel "Nos promos à venir" (bannières pleine largeur + points)
  final PageController _promoAVenirCtrl = PageController();
  int _promoAVenirPage = 0;
  Timer? _promoTimer;

  // Images des blocs promo pilotées depuis le dashboard (section -> url).
  final Map<String, String> _blocImages = {};

  @override
  void initState() {
    super.initState();
    _headerCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 250), () { if (mounted) _contentCtrl.forward(); });
    _loadStats();
    _initBloc();
    _promotionsBloc = sl<PromotionsBloc>()..add(LoadPromotionsActives());
    _fetchBlocsPromo();
    _startPromoAutoScroll();
    if (widget.user == null) {
      _compteSub = _compteBloc.stream.listen((state) {
        if (state is CompteLoaded && mounted) {
          setState(() => _liveUser = state.user);
        }
      });
      // Ne charger le profil que si un token existe (sinon 401 inutile en invité).
      sl<TokenService>().isAuthenticated.then((connecte) {
        if (connecte) _compteBloc.add(LoadCompte());
      });
    }
  }

  // Récupère les images/titres des blocs promo depuis l'API (non bloquant).
  Future<void> _fetchBlocsPromo() async {
    try {
      final blocs = await sl<PromotionsRemoteDataSource>().blocsPromo();
      if (!mounted) return;
      setState(() {
        for (final b in blocs) {
          if ((b.image ?? '').isNotEmpty) _blocImages[b.section] = b.image!;
        }
      });
    } catch (_) {/* blocs masqués → fallback sur les images par défaut */}
  }

  Future<void> _initBloc() async {
    try {
      // Récupérés via l'injection de dépendances (Dio partagé + API_BASE_URL du .env)
      final dataSource = sl<ProduitRemoteDataSource>();
      final bloc       = sl<ProduitBloc>();
      bloc.add(LoadProduits());
      if (mounted) {
        setState(() { _dataSource = dataSource; _produitBloc = bloc; });
        _fetchBoutiques();
        _fetchDecouverte();
        _fetchRayons();
        _fetchBannieres();
        _fetchPromosGroupees();
      }
    } catch (e) {
      debugPrint('Erreur init bloc: $e');
    }
  }

  Future<void> _fetchRayons() async {
    if (_dataSource == null) return;
    try {
      final list = await _dataSource!.getRayons();
      if (mounted) setState(() => _rayonsApi = list);
    } catch (_) {/* fallback sur les rayons statiques */}
  }

  Future<void> _fetchBannieres() async {
    if (_dataSource == null) return;
    try {
      final list = await _dataSource!.getBannieres();
      if (mounted) setState(() => _banniersList = list);
    } catch (_) {/* fallback sur l'asset local */}
  }

  Future<void> _fetchPromosGroupees() async {
    if (_dataSource == null) return;
    try {
      final promo = await _dataSource!.getPromotionsGroupees();
      if (mounted) setState(() => _promoGroupee = promo);
    } catch (_) {/* fallback sur les blocs promo existants */}
  }

  Future<void> _fetchBoutiques() async {
    if (_dataSource == null) return;
    setState(() { _boutiquesLoad = true; _boutiquesError = null; });
    try {
      final list = await _dataSource!.getBoutiques();
      if (mounted) setState(() { _boutiques = list; _boutiquesLoad = false; });
    } catch (e) {
      if (mounted) setState(() { _boutiquesError = e.toString(); _boutiquesLoad = false; });
    }
  }

  // Sections découverte : tendances + nouvelles boutiques (non bloquantes)
  Future<void> _fetchDecouverte() async {
    if (_dataSource == null) return;
    try {
      final t = await _dataSource!.getProduitsTendance();
      if (mounted) setState(() => _tendances = t);
    } catch (_) {/* section masquée si indisponible */}
  }

  // Défilement automatique du carrousel "Nos promos à venir".
  void _startPromoAutoScroll() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_promoAVenirCtrl.hasClients) return;
      final next = (_promoAVenirPage + 1) % _promoAVenirCount;
      _promoAVenirCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoAVenirCtrl.dispose();
    _headerCtrl.dispose();
    _contentCtrl.dispose();
    _produitBloc?.close();
    _promotionsBloc.close();
    _compteSub?.cancel();
    _compteBloc.close();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    // Commandes & favoris nécessitent une connexion : on ne les appelle pas
    // pour un invité (évite des 401 inutiles). Le panier est local.
    final connecte = await sl<TokenService>().isAuthenticated;
    try {
      int nbCommandes = 0;
      int nbFavoris = 0;
      if (connecte) {
        final commandes = await sl<CommandeRemoteDataSource>().mesCommandes();
        final favoris   = await sl<FavorisRemoteDataSource>().mesFavoris();
        nbCommandes = commandes.length;
        nbFavoris   = favoris.length;
      }
      if (!mounted) return;
      setState(() {
        _nbCommandes = nbCommandes;
        _nbFavoris   = nbFavoris;
        _nbPanier    = sl<PanierService>().nombreArticles;
        _loading     = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Ouvrir la bottom sheet d'une boutique ─────────────────────────────────
  void _openBoutiqueSheet(BoutiqueModel boutique) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BoutiqueSheet(
        boutique: boutique,
        dataSource: _dataSource,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initiales = _getInitiales(_user);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── Barre du haut (logo · cloche · se connecter · profil) ──────────
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(position: _headerSlide, child: _buildTopBar(initiales)),
          ),
          // ── Contenu défilant ──────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _produitBloc?.add(LoadProduits());
                await Future.wait([
                  _loadStats(),
                  _fetchBoutiques(),
                  _fetchDecouverte(),
                  _fetchRayons(),
                  _fetchBannieres(),
                  _fetchPromosGroupees(),
                ]);
              },
              color: _C.green,
              backgroundColor: _C.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bannière publicitaire (image adaptée au format mobile)
                          _buildImageBanner(),
                          // Bloc "Nos promos du moment" — promotions actives (même design)
                          _buildNosPromosDuMoment(),
                          // Bloc "À ne pas manquer" — carrousel horizontal + Voir tous
                          _buildANePasManquer(),
                          // Bloc "Nos rayons" — grille de catégories
                          _buildNosRayons(),
                          // Bloc "Nos promos à venir" — carrousel plein largeur
                          _buildNosPromosAVenir(),
                          // Rangée d'avantages (réductions, cadeaux, offres, paiement)
                          _buildTrustBadges(),
                          // Petite marge : la nav bar est désormais opaque (extendBody:false),
                          // donc plus besoin de compenser sa hauteur.
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre du haut ───────────────────────────────────────────────────────────
  Widget _buildTopBar(String initiales) {
    final connecte = _user != null;
    final hasPhoto = connecte && (_user?.photoProfil?.isNotEmpty ?? false);

    return Container(
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(bottom: BorderSide(color: _C.border, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
          child: Row(
            children: [
              // ── Pictogramme Yobante à gauche
              Image.asset(
                'assets/images/Logo Yobante pictogramme - Version.png',
                height: 76,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              // ── Cloche notifications
              _buildTopIcon(
                icon: Icons.notifications_none_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
              ),
              const SizedBox(width: 10),
              // ── Bouton "Se connecter" (invité uniquement)
              if (!connecte) ...[
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _C.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Se connecter',
                        style: GoogleFonts.dmSans(
                            fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.white)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              // ── Icône utilisateur → page profil
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProfilPage(user: _user)),
                ),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _C.greenLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.green.withOpacity(0.15)),
                  ),
                  child: hasPhoto
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            _user!.photoProfil!,
                            width: 40, height: 40, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(initiales,
                                  style: GoogleFonts.sora(
                                      fontSize: 14, fontWeight: FontWeight.w800, color: _C.green)),
                            ),
                          ),
                        )
                      : connecte
                          ? Center(
                              child: Text(initiales,
                                  style: GoogleFonts.sora(
                                      fontSize: 14, fontWeight: FontWeight.w800, color: _C.green)),
                            )
                          : const Icon(Icons.person_outline_rounded, color: _C.green, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: _C.green, size: 22),
      ),
    );
  }

  // ── Bannière publicitaire (image adaptée au format mobile) ──────────────────
  Widget _buildImageBanner() {
    // Première bannière depuis l'API si disponible, sinon fallback sur l'asset.
    String? apiImageUrl;
    if (_banniersList.isNotEmpty) {
      final first = _banniersList.first;
      if (first is Map) {
        apiImageUrl = first['image']?.toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PromotionsActivesPage()),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: apiImageUrl != null && apiImageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: apiImageUrl,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  placeholder: (_, __) => Container(
                    height: 160,
                    color: _C.greenLight,
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: _C.green, strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Image.asset(
                    'assets/images/banniere du haut.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                )
              : Image.asset(
                  'assets/images/banniere du haut.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
        ),
      ),
    );
  }

  // ── Bloc "À ne pas manquer" (carrousel horizontal + Voir tous) ──────────────
  static const List<List<Color>> _adGradients = [
    [Color(0xFF163A9E), Color(0xFF2E5BD6)],
    [Color(0xFFF5C518), Color(0xFFFFA000)],
    [Color(0xFF0F9D58), Color(0xFF34C759)],
    [Color(0xFFE53935), Color(0xFFFF7043)],
  ];

  final List<_Ad> _adsDefault = const [
    _Ad(tag: "JUSQU'À", big: '-50%', sub: 'sur une sélection de produits'),
    _Ad(tag: 'LIVRAISON', big: 'Gratuite', sub: 'en point relais à Touba'),
    _Ad(tag: 'NOUVEAU', big: 'Électro', sub: 'Découvrez nos nouveautés'),
  ];

  // Images publicitaires de la section "Nos promos du moment".
  static const List<String> _promoImages = [
    'assets/images/promo1.png',
    'assets/images/promo2.png',
    'assets/images/promo3.png',
  ];

  // ── Bloc "Nos promos du moment" (bannières images + Voir tous) ──────────────
  Widget _buildNosPromosDuMoment() {
    // Priorité : promotions groupées API → blocs dashboard → assets locaux
    final apiPromos = _promoGroupee?.nosPromosDuMoment ?? [];
    final apiImages = apiPromos
        .whereType<Map>()
        .map((p) => (p['image'] ?? p['produit']?['image'] ?? '').toString())
        .where((url) => url.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text('Nos promos du moment',
                style: GoogleFonts.sora(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: _C.black, letterSpacing: -0.4)),
          ),
          const SizedBox(height: 14),
          if (_blocImages['nos_promos_du_moment'] != null)
            _buildBlocBanner(_blocImages['nos_promos_du_moment']!)
          else if (apiImages.isNotEmpty)
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: apiImages.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  if (i == apiImages.length) return _buildVoirTousCard();
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PromotionsActivesPage()),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CachedNetworkImage(
                        imageUrl: apiImages[i],
                        width: 302,
                        height: 170,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 302,
                          height: 170,
                          decoration: BoxDecoration(
                            color: _C.greenLight,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 302,
                          height: 170,
                          decoration: BoxDecoration(
                            color: _C.greenLight,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.image_outlined, color: _C.label),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: _promoImages.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  if (i == _promoImages.length) return _buildVoirTousCard();
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PromotionsActivesPage()),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        _promoImages[i],
                        width: 302,
                        height: 170,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Bannière pleine largeur d'un bloc promo (image gérée depuis le dashboard).
  Widget _buildBlocBanner(String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PromotionsActivesPage()),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            url,
            width: double.infinity,
            height: 170,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  // ── Bloc "À ne pas manquer" (sélection éditoriale, même design) ─────────────
  Widget _buildANePasManquer() {
    // Promotions "à ne pas rater" depuis l'API si disponibles
    final apiPromos = _promoGroupee?.aNesPasRater ?? [];
    final apiImages = apiPromos
        .whereType<Map>()
        .map((p) => (p['image'] ?? p['produit']?['image'] ?? '').toString())
        .where((url) => url.isNotEmpty)
        .toList();

    final int count = _adsDefault.length;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text('À ne pas manquer',
                style: GoogleFonts.sora(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: _C.black, letterSpacing: -0.4)),
          ),
          const SizedBox(height: 14),
          if (_blocImages['a_ne_pas_rater'] != null)
            _buildBlocBanner(_blocImages['a_ne_pas_rater']!)
          else if (apiImages.isNotEmpty)
            SizedBox(
              height: 178,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: apiImages.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  if (i == apiImages.length) return _buildVoirTousCard();
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PromotionsActivesPage()),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: apiImages[i],
                        width: 268,
                        height: 178,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 268,
                          height: 178,
                          color: _C.greenLight,
                        ),
                        errorWidget: (_, __, ___) {
                          // Fallback sur la carte dégradé statique
                          final g = _adGradients[i % _adGradients.length];
                          final darkText = i % _adGradients.length == 1;
                          final ad = _adsDefault[i % _adsDefault.length];
                          return _buildAdCard(
                            gradient: g, darkText: darkText,
                            tag: ad.tag, big: ad.big, sub: ad.sub,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            )
          else
            SizedBox(
              height: 178,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: count + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  if (i == count) return _buildVoirTousCard();
                  final g = _adGradients[i % _adGradients.length];
                  final darkText = i % _adGradients.length == 1;
                  final ad = _adsDefault[i];
                  return _buildAdCard(
                    gradient: g, darkText: darkText,
                    tag: ad.tag, big: ad.big, sub: ad.sub,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdCard({
    required List<Color> gradient,
    required bool darkText,
    required String tag,
    required String big,
    required String sub,
  }) {
    final Color fg = darkText ? _C.black : _C.white;
    final Color pillBg = darkText ? Colors.black.withOpacity(0.10) : Colors.white.withOpacity(0.20);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PromotionsActivesPage()),
      ),
      child: Container(
        width: 268,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: gradient.first.withOpacity(0.28),
                blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(8)),
              child: Text(tag,
                  style: GoogleFonts.dmSans(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: fg, letterSpacing: 0.6)),
            ),
            const Spacer(),
            Text(big,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                    fontSize: 26, fontWeight: FontWeight.w900,
                    color: fg, letterSpacing: -1, height: 1.05)),
            const SizedBox(height: 4),
            Text(sub,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: fg.withOpacity(0.9))),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: darkText ? _C.black : _C.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('En profiter',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: darkText ? _C.white : gradient.first)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoirTousCard() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PromotionsActivesPage()),
      ),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: _C.greenLight, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: _C.green, size: 22),
            ),
            const SizedBox(height: 12),
            Text('Voir tous',
                style: GoogleFonts.sora(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _C.green)),
          ],
        ),
      ),
    );
  }

  // ── Bloc "Nos rayons" (grille de catégories) ────────────────────────────────
  static const List<_Rayon> _rayons = [
    _Rayon('Bébé', Icons.child_care_rounded),
    _Rayon('Dépannage', Icons.build_rounded),
    _Rayon('Petfood & Animalerie', Icons.pets_rounded),
    _Rayon('Boissons', Icons.local_drink_rounded),
    _Rayon("Petit-déj'", Icons.free_breakfast_rounded),
    _Rayon('Boulangerie', Icons.bakery_dining_rounded),
    _Rayon('Huiles, Sauces & Épices', Icons.science_rounded),
    _Rayon('Pâtes, Riz & Céréales', Icons.rice_bowl_rounded),
    _Rayon('Frais & Surgelés', Icons.ac_unit_rounded),
    _Rayon('Fruits & Légumes', Icons.eco_rounded),
    _Rayon('Snacking', Icons.cookie_rounded),
    _Rayon('Conserves', Icons.inventory_2_rounded),
    _Rayon('Entretien Maison', Icons.cleaning_services_rounded),
    _Rayon('Hygiène & Beauté', Icons.water_drop_rounded),
    _Rayon('Adulte', Icons.shield_rounded),
  ];

  Widget _buildNosRayons() {
    // Utiliser les rayons API si disponibles, sinon les rayons statiques.
    final hasApiRayons = _rayonsApi.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec petit trait doré
          Row(
            children: [
              Container(
                width: 18, height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C518),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('Nos rayons',
                  style: GoogleFonts.sora(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: _C.black, letterSpacing: -0.4)),
            ],
          ),
          const SizedBox(height: 14),
          if (hasApiRayons)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: _rayonsApi.length,
              itemBuilder: (_, i) => _buildRayonApiCard(_rayonsApi[i]),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: _rayons.length,
              itemBuilder: (_, i) => _buildRayonCard(_rayons[i]),
            ),
        ],
      ),
    );
  }

  // Carte rayon provenant de l'API (RayonModel).
  Widget _buildRayonApiCard(RayonModel rayon) {
    final hasImage = rayon.image != null && rayon.image!.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RayonProduitsPage(rayon: rayon),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: _C.green,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: _C.green.withOpacity(0.18),
                blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: rayon.image!,
                  width: 28, height: 28, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.category_rounded, color: _C.white, size: 21),
                ),
              )
            else
              const Icon(Icons.category_rounded, color: _C.white, size: 21),
            const SizedBox(height: 6),
            Text(rayon.nom,
                textAlign: TextAlign.center,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                    fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: _C.white, height: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildRayonCard(_Rayon rayon) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategorieProduitsPage(titre: rayon.label, icon: rayon.icon),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: _C.green,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: _C.green.withOpacity(0.18),
                blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(rayon.icon, color: _C.white, size: 21),
            const SizedBox(height: 6),
            Text(rayon.label,
                textAlign: TextAlign.center,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                    fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: _C.white, height: 1.1)),
          ],
        ),
      ),
    );
  }

  // ── Bloc "Nos promos à venir" (bannières images) ────────────────────────────
  static const List<String> _promoAVenirImages = [
    'assets/images/tabaski.png',
    'assets/images/rentree des classes.png',
    'assets/images/black friday.png',
  ];

  // Nombre de bannières effectives du bloc "à venir".
  int get _promoAVenirCount {
    if (_blocImages['nos_promos_a_venir'] != null) return 1;
    final apiCount = (_promoGroupee?.nosPromosAVenir ?? [])
        .whereType<Map>()
        .map((p) => (p['image'] ?? p['produit']?['image'] ?? '').toString())
        .where((url) => url.isNotEmpty)
        .length;
    return apiCount > 0 ? apiCount : _promoAVenirImages.length;
  }

  Widget _buildNosPromosAVenir() {
    final double bannerW = MediaQuery.of(context).size.width - 32;
    final double bannerH = bannerW / 1.776; // format 16:9 des bannières
    final String? apiImg = _blocImages['nos_promos_a_venir'];

    // Images depuis les promotions groupées "à venir" si disponibles
    final apiPromoAVenir = _promoGroupee?.nosPromosAVenir ?? [];
    final apiPromoImages = apiPromoAVenir
        .whereType<Map>()
        .map((p) => (p['image'] ?? p['produit']?['image'] ?? '').toString())
        .where((url) => url.isNotEmpty)
        .toList();

    final List<String> imgs;
    final bool isNetwork;
    if (apiImg != null) {
      imgs = [apiImg];
      isNetwork = true;
    } else if (apiPromoImages.isNotEmpty) {
      imgs = apiPromoImages;
      isNetwork = true;
    } else {
      imgs = _promoAVenirImages;
      isNetwork = false;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 18, height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5C518),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Nos promos à venir',
                    style: GoogleFonts.sora(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: _C.black, letterSpacing: -0.4)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PromotionsActivesPage()),
                  ),
                  child: Text('Voir tout',
                      style: GoogleFonts.dmSans(
                          fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.green)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Carrousel plein largeur
          SizedBox(
            height: bannerH,
            child: PageView.builder(
              controller: _promoAVenirCtrl,
              itemCount: imgs.length,
              onPageChanged: (i) => setState(() => _promoAVenirPage = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PromotionsActivesPage()),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: isNetwork
                        ? CachedNetworkImage(
                            imageUrl: imgs[i],
                            width: bannerW,
                            height: bannerH,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: _C.greenLight,
                              child: const Icon(Icons.image_outlined, color: _C.label),
                            ),
                          )
                        : Image.asset(
                            imgs[i],
                            width: bannerW,
                            height: bannerH,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Points de pagination
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(imgs.length, (i) {
                final active = i == _promoAVenirPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? _C.green : _C.green.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rangée d'avantages (sous les promos à venir) ────────────────────────────
  Widget _buildTrustBadges() {
    const items = <(IconData, String)>[
      (Icons.percent_rounded, 'Des réductions\nexceptionnelles'),
      (Icons.card_giftcard_rounded, 'Des cadeaux\nsurprises'),
      (Icons.schedule_rounded, 'Offres limitées\ndans le temps'),
      (Icons.verified_user_rounded, 'Paiement 100%\nsécurisé'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 6),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          // Aligne toutes les icônes au même niveau (en haut), quelle que soit
          // la hauteur du texte en dessous.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map((it) => Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: const BoxDecoration(
                              color: _C.greenLight, shape: BoxShape.circle),
                          child: Icon(it.$1, color: _C.green, size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(it.$2,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                                fontSize: 9.5, fontWeight: FontWeight.w700,
                                color: _C.green, height: 1.25)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── Statistiques ──────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Row(
        children: [
          Expanded(child: _buildStatChip(icon: Icons.receipt_long_rounded,    label: 'Commandes', value: _nbCommandes.toString(), color: _C.green)),
          const SizedBox(width: 10),
          Expanded(child: _buildStatChip(icon: Icons.favorite_border_rounded, label: 'Favoris',   value: _nbFavoris.toString(),   color: const Color(0xFFE53935))),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PanierPage()),
              ),
              child: _buildStatChip(icon: Icons.shopping_cart_outlined, label: 'Voir panier', value: _nbPanier.toString(), color: _C.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border)),
      child: Column(
        children: [
          Container(width: 34, height: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: color)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: _C.black)),
          Text(label,  style: GoogleFonts.dmSans(fontSize: 10, color: _C.label, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── En-tête section ───────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: _C.black)),
          Text('Voir tout', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: _C.green)),
        ],
      ),
    );
  }

  // ── Liste boutiques dynamique ─────────────────────────────────────────────
  Widget _buildShopList() {
    if (_dataSource == null || _boutiquesLoad) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5)),
      );
    }
    if (_boutiquesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: _C.orange, size: 40),
            const SizedBox(height: 8),
            Text('Erreur: $_boutiquesError', style: GoogleFonts.dmSans(color: _C.orange), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _fetchBoutiques,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(12)),
                child: Text('Réessayer', style: GoogleFonts.dmSans(color: _C.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }
    if (_boutiques.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('Aucune boutique disponible', style: GoogleFonts.dmSans(color: _C.label))),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(children: _boutiques.map(_buildShopItem).toList()),
    );
  }

  Widget _buildShopItem(BoutiqueModel boutique) {
    final hasLogo   = boutique.logo != null && boutique.logo!.isNotEmpty;
    final horaires  = boutique.horaires;
    final sousTitre = boutique.localisation.isNotEmpty ? boutique.localisation : boutique.description;

    return GestureDetector(
      onTap: () => _openBoutiqueSheet(boutique),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _C.greenLight,
                borderRadius: BorderRadius.circular(12),
                image: hasLogo
                    ? DecorationImage(image: NetworkImage(boutique.logo!), fit: BoxFit.cover)
                    : null,
              ),
              child: hasLogo ? null : const Icon(Icons.storefront_rounded, color: _C.green, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(boutique.nom,
                      style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _C.black)),
                  Text(sousTitre,
                      style: GoogleFonts.dmSans(fontSize: 11, color: _C.label),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (horaires.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 10, color: _C.green),
                      const SizedBox(width: 3),
                      Text(horaires, style: GoogleFonts.dmSans(fontSize: 10, color: _C.green)),
                    ]),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(10)),
              child: Text(boutique.vendeurNomComplet,
                  style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: _C.sub),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            // ── Icône ouvrir boutique ──────────────────────────────────────
            GestureDetector(
              onTap: () => _openBoutiqueSheet(boutique),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _C.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chevron_right_rounded, color: _C.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Tendances (horizontale) ───────────────────────────────────────
  Widget _buildTendances() {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: _tendances.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) =>
            SizedBox(width: 150, child: _buildProductCard(_tendances[i])),
      ),
    );
  }

  // ── Section Nouvelles boutiques ────────────────────────────────────────────
  Widget _buildNouvelles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(children: _nouvelles.map(_buildNouvelleBoutiqueItem).toList()),
    );
  }

  Widget _buildNouvelleBoutiqueItem(BoutiqueModel b) {
    final hasLogo = b.logo != null && b.logo!.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BoutiqueDetailPage(boutique: b)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _C.greenLight,
                borderRadius: BorderRadius.circular(12),
                image: hasLogo
                    ? DecorationImage(image: NetworkImage(b.logo!), fit: BoxFit.cover)
                    : null,
              ),
              child: hasLogo
                  ? null
                  : const Icon(Icons.storefront_rounded, color: _C.green, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _C.black)),
                  if (b.localisation.isNotEmpty)
                    Text(b.localisation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(fontSize: 11, color: _C.label)),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _C.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded, color: _C.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grille produits dynamique via Bloc ────────────────────────────────────
  Widget _buildProductGrid() {
    if (_produitBloc == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: BlocBuilder<ProduitBloc, ProduitState>(
        bloc: _produitBloc,
        builder: (context, state) {
          if (state is ProduitLoading) {
            return const Center(child: Padding(padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5)));
          } else if (state is ProduitLoaded) {
            final produits = state.produits;
            if (produits.isEmpty) {
              return Center(child: Padding(padding: const EdgeInsets.all(32),
                  child: Text('Aucun produit disponible', style: GoogleFonts.dmSans(color: _C.label))));
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.80),
              itemCount: produits.length,
              itemBuilder: (_, i) => _buildProductCard(produits[i]),
            );
          } else if (state is ProduitError) {
            return Center(child: Padding(padding: const EdgeInsets.all(32),
                child: Column(children: [
                  const Icon(Icons.error_outline_rounded, color: _C.orange, size: 40),
                  const SizedBox(height: 8),
                  Text('Erreur: ${state.message}', style: GoogleFonts.dmSans(color: _C.orange), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _produitBloc?.add(LoadProduits()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(12)),
                      child: Text('Réessayer', style: GoogleFonts.dmSans(color: _C.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ])));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProductCard(ProduitModel produit) {
    return ProduitGridCard(
      produit: produit,
      onTap: () => showProduitModal(context, produit),
      onAdd: () => ajouterProduitAuPanier(context, produit),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _getInitiales(User? user) {
    if (user == null) return '?';
    final p = user.prenom?.isNotEmpty == true ? user.prenom![0] : '';
    final n = user.nom?.isNotEmpty    == true ? user.nom![0]    : '';
    return '$p$n'.toUpperCase();
  }

}

// ════════════════════════════════════════════════════════════════════════════
// Bottom Sheet — Produits d'une boutique
// ════════════════════════════════════════════════════════════════════════════
class _BoutiqueSheet extends StatefulWidget {
  final BoutiqueModel            boutique;
  final ProduitRemoteDataSource? dataSource;

  const _BoutiqueSheet({required this.boutique, required this.dataSource});

  @override
  State<_BoutiqueSheet> createState() => _BoutiqueSheetState();
}

class _BoutiqueSheetState extends State<_BoutiqueSheet> {
  List<ProduitModel> _produits = [];
  bool               _loading  = true;
  String?            _error;

  @override
  void initState() {
    super.initState();
    _loadProduits();
  }

  Future<void> _loadProduits() async {
    if (widget.dataSource == null) {
      setState(() { _loading = false; _error = 'Source de données indisponible'; });
      return;
    }
    try {
      final list = await widget.dataSource!.getProduitsByBoutique(widget.boutique.id);
      if (mounted) setState(() { _produits = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Appel WhatsApp ─────────────────────────────────────────────
  Future<void> _contactWhatsapp(String produitId) async {
    if (widget.dataSource == null) return;

    try {
      // 1️⃣ Récupère l'URL depuis le backend
      final url = await widget.dataSource!.getWhatsappUrl(produitId);
      logDebug('🔗 URL WhatsApp finale: $url');

      // 2️⃣ Parse l'URL
      final uri = Uri.parse(url);

      // 3️⃣ Vérifie si l'appareil peut ouvrir le lien
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // 4️⃣ Affiche un message si WhatsApp n'est pas installé
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Impossible d\'ouvrir WhatsApp. Veuillez vérifier que l\'application est installée.',
                style: GoogleFonts.dmSans(color: _C.white),
              ),
              backgroundColor: _C.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString()}',
              style: GoogleFonts.dmSans(color: _C.white),
            ),
            backgroundColor: _C.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = widget.boutique.logo != null && widget.boutique.logo!.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Drag handle
            const SizedBox(height: 10),
            Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),

            // ── En-tête boutique
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _C.greenLight, borderRadius: BorderRadius.circular(14),
                      image: hasLogo
                          ? DecorationImage(image: NetworkImage(widget.boutique.logo!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: hasLogo ? null : const Icon(Icons.storefront_rounded, color: _C.green, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.boutique.nom,
                            style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800, color: _C.black)),
                        if (widget.boutique.localisation.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: _C.green),
                            const SizedBox(width: 3),
                            Text(widget.boutique.localisation,
                                style: GoogleFonts.dmSans(fontSize: 11, color: _C.label)),
                          ]),
                        if (widget.boutique.horaires.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: _C.green),
                            const SizedBox(width: 3),
                            Text(widget.boutique.horaires,
                                style: GoogleFonts.dmSans(fontSize: 11, color: _C.green)),
                          ]),
                        const SizedBox(height: 4),
                        if (widget.boutique.vendeurNomComplet.isNotEmpty || widget.boutique.vendeurNumero.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.person_outline, size: 12, color: _C.green),
                            const SizedBox(width: 3),
                            Text('${widget.boutique.vendeurNomComplet} (${widget.boutique.vendeurNumero})',
                                style: GoogleFonts.dmSans(fontSize: 11, color: _C.label)),
                          ]),
                      ],
                    ),
                  ),
                  // Fermer
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.close_rounded, size: 18, color: _C.sub)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Divider(color: _C.border, thickness: 1, height: 1),
            const SizedBox(height: 4),

            // ── Compteur produits
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(children: [
                  Text('${_produits.length} produit${_produits.length > 1 ? 's' : ''}',
                      style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _C.black)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(8)),
                    child: Text('En stock', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: _C.green)),
                  ),
                ]),
              ),

            const SizedBox(height: 12),

            // ── Corps : grille ou états
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5))
                  : _error != null
                  ? _buildError()
                  : _produits.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12,
                    mainAxisSpacing: 12, childAspectRatio: 0.75),
                itemCount: _produits.length,
                itemBuilder: (_, i) => _buildProductCard(_produits[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, color: _C.orange, size: 40),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_error!, style: GoogleFonts.dmSans(color: _C.orange), textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () { setState(() { _loading = true; _error = null; }); _loadProduits(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(12)),
            child: Text('Réessayer', style: GoogleFonts.dmSans(color: _C.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.inventory_2_outlined, color: _C.label, size: 48),
        const SizedBox(height: 12),
        Text('Aucun produit dans cette boutique',
            style: GoogleFonts.dmSans(fontSize: 14, color: _C.label)),
      ]),
    );
  }

  // ── Carte produit avec bouton WhatsApp ────────────────────────────────────
  Widget _buildProductCard(ProduitModel produit) {
    return Container(
      decoration: BoxDecoration(
          color: _C.bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                image: produit.image.isNotEmpty
                    ? DecorationImage(image: NetworkImage(produit.image), fit: BoxFit.cover)
                    : null,
              ),
              child: Stack(children: [
                Positioned(top: 8, right: 8,
                    child: Container(width: 28, height: 28,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                        child: const Icon(Icons.favorite_border_rounded, size: 14, color: _C.label))),
              ]),
            ),
          ),
          // Infos + boutons
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produit.nom, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: _C.black),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(produit.ville, style: GoogleFonts.dmSans(fontSize: 10, color: _C.label)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: produit.prix, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800, color: _C.black)),
                      TextSpan(text: ' F',         style: GoogleFonts.dmSans(fontSize: 10, color: _C.label)),
                    ])),
                    // ── Bouton WhatsApp ──────────────────────────────────
                    GestureDetector(
                      onTap: () => _contactWhatsapp(produit.id),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _C.whatsapp,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chat_rounded, color: _C.white, size: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}