import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';

import 'produit_detail_page.dart';
import 'produit_page.dart';
import 'package:yobante/core/connection/auth_interceptor.dart';

import '../../../../../injection_container.dart';
import '../../../data/models/boutique_model.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/datasources/produit_remote_datasource.dart';
import '../../../../favoris/data/datasources/favoris_remote_datasource.dart';
import '../../../../commande/data/services/panier_service.dart';
import '../../../../commande/data/models/panier_item.dart';
import '../../../../commande/presentation/pages/panier_page.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const green      = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const surface    = Color(0xFFF7F9FC);
  static const border     = Color(0xFFDDE3EF);
  static const label      = Color(0xFF9AA3B2);
  static const sub        = Color(0xFF6B7280);
  static const red        = Color(0xFFE53935);
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE : Recherche / liste des boutiques
// ══════════════════════════════════════════════════════════════════════════════
class BoutiquesPage extends StatefulWidget {
  const BoutiquesPage({super.key});

  @override
  State<BoutiquesPage> createState() => _BoutiquesPageState();
}

class _BoutiquesPageState extends State<BoutiquesPage> {
  final _produitDS = sl<ProduitRemoteDataSource>();
  final _favDS     = sl<FavorisRemoteDataSource>();
  final _searchCtrl = TextEditingController();

  List<BoutiqueModel> _all = [];
  List<BoutiqueModel> _filtered = [];
  Set<String> _favIds = {};
  bool _loading = true;
  String? _error;
  String _mode = 'toutes'; // toutes | verifiees | nouvelles

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_mode == 'proches') { await _loadProches(); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final boutiques = _mode == 'verifiees'
          ? await _produitDS.getBoutiquesVerifiees()
          : _mode == 'nouvelles'
              ? await _produitDS.getNouvellesBoutiques()
              : await _produitDS.getBoutiques();
      Set<String> favIds = {};
      try {
        final favs = await _favDS.mesFavoris();
        favIds = favs.map((b) => b.id).toSet();
      } catch (_) {/* favoris indisponibles → aucun favori */}
      if (!mounted) return;
      setState(() {
        _all = boutiques;
        _filtered = _applyFilter(_searchCtrl.text, boutiques);
        _favIds = favIds;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Impossible de charger les boutiques'; _loading = false; });
    }
  }

  // Mode « Proches » : géolocalisation + GET /acheteurs/boutiques-proches
  Future<void> _loadProches() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() {
          _error = 'Activez la localisation de votre appareil';
          _loading = false;
        });
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _error = 'Autorisation de localisation refusée';
          _loading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final boutiques =
          await _produitDS.getBoutiquesProches(pos.latitude, pos.longitude);
      Set<String> favIds = _favIds;
      try {
        final favs = await _favDS.mesFavoris();
        favIds = favs.map((b) => b.id).toSet();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _all = boutiques;
        _filtered = _applyFilter(_searchCtrl.text, boutiques);
        _favIds = favIds;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Localisation indisponible'; _loading = false; });
    }
  }

  List<BoutiqueModel> _applyFilter(String q, List<BoutiqueModel> source) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return source;
    return source
        .where((b) =>
            b.nom.toLowerCase().contains(query) ||
            b.localisation.toLowerCase().contains(query) ||
            b.vendeurNomComplet.toLowerCase().contains(query))
        .toList();
  }

  void _onSearch(String q) {
    setState(() => _filtered = _applyFilter(q, _all));
  }

  Future<void> _toggleFav(BoutiqueModel b) async {
    final isFav = _favIds.contains(b.id);
    setState(() => isFav ? _favIds.remove(b.id) : _favIds.add(b.id));
    try {
      if (isFav) {
        await _favDS.supprimer(b.id);
      } else {
        await _favDS.ajouter(b.id);
      }
    } catch (_) {
      if (!mounted) return;
      // Revert en cas d'échec réseau
      setState(() => isFav ? _favIds.add(b.id) : _favIds.remove(b.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action sur le favori échouée')),
      );
    }
  }

  Future<void> _ouvrirDetail(BoutiqueModel b) async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BoutiqueDetailPage(
          boutique: b,
          initialFavori: _favIds.contains(b.id),
        ),
      ),
    );
    // La page de détail renvoie l'état favori final → on synchronise la liste.
    if (res != null && mounted) {
      setState(() => res ? _favIds.add(b.id) : _favIds.remove(b.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: Text('Boutiques',
            style: GoogleFonts.sora(fontWeight: FontWeight.w800, color: _C.black)),
        actions: [
          IconButton(
            tooltip: 'Mon panier',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PanierPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearch,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.dmSans(color: _C.black, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher une boutique, une ville…',
          hintStyle: GoogleFonts.dmSans(color: _C.label, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.label),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: _C.label, size: 18),
                  onPressed: () { _searchCtrl.clear(); _onSearch(''); },
                ),
          filled: true,
          fillColor: _C.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
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
    );
  }

  Widget _buildChips() {
    Widget chip(String id, String labelTxt) {
      final sel = _mode == id;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () {
            if (_mode != id) { setState(() => _mode = id); _load(); }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _C.green : _C.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? _C.green : _C.border),
            ),
            child: Text(labelTxt,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? _C.white : _C.sub)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        children: [
          chip('toutes', 'Toutes'),
          chip('proches', 'Proches'),
          chip('verifiees', 'Vérifiées'),
          chip('nouvelles', 'Nouvelles'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5));
    }
    if (_error != null) {
      return _ErrorRetry(message: _error!, onRetry: _load);
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 56, color: _C.label),
            const SizedBox(height: 12),
            Text(
              _all.isEmpty ? 'Aucune boutique disponible' : 'Aucun résultat',
              style: GoogleFonts.dmSans(color: _C.label),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _C.green,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildBoutiqueCard(_filtered[i]),
      ),
    );
  }

  Widget _buildBoutiqueCard(BoutiqueModel b) {
    final hasLogo = b.logo != null && b.logo!.isNotEmpty;
    final isFav   = _favIds.contains(b.id);
    final sousTitre = b.localisation.isNotEmpty ? b.localisation : b.description;

    return GestureDetector(
      onTap: () => _ouvrirDetail(b),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasLogo
                  ? CachedNetworkImage(
                      imageUrl: b.logo!,
                      width: 52, height: 52, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _logoFallback(),
                    )
                  : _logoFallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.nom,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: _C.black)),
                  const SizedBox(height: 2),
                  if (sousTitre.isNotEmpty)
                    Text(sousTitre,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(fontSize: 11, color: _C.label)),
                  if (b.horaires.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 11, color: _C.green),
                      const SizedBox(width: 3),
                      Text(b.horaires, style: GoogleFonts.dmSans(fontSize: 10, color: _C.green)),
                    ]),
                  ],
                ],
              ),
            ),
            // Bouton favori
            IconButton(
              onPressed: () => _toggleFav(b),
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? _C.red : _C.label,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoFallback() => Container(
        width: 52, height: 52,
        color: _C.greenLight,
        child: const Icon(Icons.storefront_rounded, color: _C.green, size: 24),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE : Détail d'une boutique (produits + achat + favori)
// ══════════════════════════════════════════════════════════════════════════════
class BoutiqueDetailPage extends StatefulWidget {
  final BoutiqueModel boutique;
  final bool initialFavori;

  const BoutiqueDetailPage({
    super.key,
    required this.boutique,
    this.initialFavori = false,
  });

  @override
  State<BoutiqueDetailPage> createState() => _BoutiqueDetailPageState();
}

class _BoutiqueDetailPageState extends State<BoutiqueDetailPage> {
  final _produitDS = sl<ProduitRemoteDataSource>();
  final _favDS     = sl<FavorisRemoteDataSource>();
  final _panier    = sl<PanierService>();

  List<ProduitModel> _produits = [];
  bool _loading = true;
  String? _error;
  late bool _favori = widget.initialFavori;

  @override
  void initState() {
    super.initState();
    _loadProduits();
  }

  Future<void> _loadProduits() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _produitDS.getProduitsByBoutique(widget.boutique.id);
      if (!mounted) return;
      setState(() { _produits = list; _loading = false; });
    } catch (_) {
      // Le backend renvoie une erreur quand la boutique n'a pas de produit :
      // on traite ça comme une liste vide, pas une erreur bloquante.
      if (!mounted) return;
      setState(() { _produits = []; _loading = false; });
    }
  }

  Future<void> _toggleFav() async {
    final avant = _favori;
    setState(() => _favori = !avant);
    try {
      if (avant) {
        await _favDS.supprimer(widget.boutique.id);
      } else {
        await _favDS.ajouter(widget.boutique.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _favori = avant);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action sur le favori échouée')),
      );
    }
  }

  Future<void> _ajouterAuPanier(ProduitModel p) async {
    await _panier.ajouter(PanierItem(
      produitId: p.id,
      nom: p.nom,
      prix: double.tryParse(p.prix) ?? 0,
      image: p.image,
      vendeurId: p.vendeurId,
      vendeurNom: p.boutiqueNom.trim().isNotEmpty ? p.boutiqueNom : p.vendeurNom,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p.nom} ajouté au panier'),
        backgroundColor: _C.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () => AuthInterceptor.navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const PanierPage()),
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      try {
        controller.close();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.boutique;
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_favori);
        return false;
      },
      child: Scaffold(
        backgroundColor: _C.bg,
        appBar: AppBar(
          backgroundColor: _C.white,
          elevation: 0.5,
          foregroundColor: _C.black,
          title: Text(b.nom,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sora(fontWeight: FontWeight.w800, color: _C.black)),
          actions: [
            IconButton(
              onPressed: _toggleFav,
              icon: Icon(
                _favori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _favori ? _C.red : _C.black,
              ),
            ),
            IconButton(
              tooltip: 'Mon panier',
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PanierPage()),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildHeader(b),
            Expanded(child: _buildProduits()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BoutiqueModel b) {
    final hasLogo = b.logo != null && b.logo!.isNotEmpty;
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: hasLogo
                ? CachedNetworkImage(
                    imageUrl: b.logo!,
                    width: 60, height: 60, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _logoFallback(),
                  )
                : _logoFallback(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.localisation.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: _C.green),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(b.localisation,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(fontSize: 12, color: _C.sub)),
                    ),
                  ]),
                if (b.horaires.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: _C.green),
                    const SizedBox(width: 3),
                    Text(b.horaires, style: GoogleFonts.dmSans(fontSize: 12, color: _C.green)),
                  ]),
                ],
                if (b.vendeurNomComplet.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 13, color: _C.green),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(b.vendeurNomComplet,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(fontSize: 12, color: _C.sub)),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProduits() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5));
    }
    if (_error != null) {
      return _ErrorRetry(message: _error!, onRetry: _loadProduits);
    }
    if (_produits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56, color: _C.label),
            const SizedBox(height: 12),
            Text('Aucun produit dans cette boutique',
                style: GoogleFonts.dmSans(color: _C.label)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
      ),
      itemCount: _produits.length,
      itemBuilder: (_, i) => _buildProduitCard(_produits[i]),
    );
  }

  Widget _buildProduitCard(ProduitModel p) {
    return ProduitGridCard(
      produit: p,
      onTap: () => showProduitModal(context, p),
      onAdd: () => _ajouterAuPanier(p),
    );
  }

  Widget _logoFallback() => Container(
        width: 60, height: 60,
        color: _C.greenLight,
        child: const Icon(Icons.storefront_rounded, color: _C.green, size: 26),
      );
}

// ── Widget d'erreur réutilisable ────────────────────────────────────────────────
class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5722), size: 44),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: _C.sub)),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(color: _C.black, borderRadius: BorderRadius.circular(12)),
              child: Text('Réessayer', style: GoogleFonts.dmSans(color: _C.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
