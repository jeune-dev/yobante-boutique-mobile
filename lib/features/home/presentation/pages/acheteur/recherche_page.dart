import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yobante/core/connection/auth_interceptor.dart';

import '../../../../../injection_container.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/models/boutique_model.dart';
import '../../../data/datasources/produit_remote_datasource.dart';
import '../../../data/rayons_catalogue.dart';
import '../../../../commande/data/services/panier_service.dart';
import '../../../../commande/data/models/panier_item.dart';
import '../../../../commande/presentation/pages/panier_page.dart';
import '../../../../promotions/presentation/pages/promotions_actives_page.dart';
import 'boutiques_page.dart';
import 'categorie_produits_page.dart';

class _C {
  static const green      = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const surface    = Color(0xFFF7F9FC);
  static const field      = Color(0xFFF0F2F7);
  static const border     = Color(0xFFDDE3EF);
  static const divider    = Color(0xFFEDF0F5);
  static const label      = Color(0xFF9AA3B2);
  static const sub        = Color(0xFF6B7280);
}

/// Page « Rechercher » : navigation par rayons (grille de catégories → sous-rayons)
/// + recherche texte globale produits/boutiques (GET /acheteurs/recherche).
class RechercheGlobalePage extends StatefulWidget {
  const RechercheGlobalePage({super.key});

  @override
  State<RechercheGlobalePage> createState() => _RechercheGlobalePageState();
}

class _RechercheGlobalePageState extends State<RechercheGlobalePage> {
  final _ds = sl<ProduitRemoteDataSource>();
  final _panier = sl<PanierService>();
  final _ctrl = TextEditingController();

  List<ProduitModel> _produits = [];
  List<BoutiqueModel> _boutiques = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _searched = true; _error = null; });
    try {
      final res = await _ds.rechercheGlobale(q);
      if (!mounted) return;
      setState(() {
        _produits = res.produits;
        _boutiques = res.boutiques;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Recherche impossible'; _loading = false; });
    }
  }

  void _clearSearch() {
    _ctrl.clear();
    setState(() { _searched = false; _produits = []; _boutiques = []; _error = null; });
    FocusScope.of(context).unfocus();
  }

  Future<void> _addCart(ProduitModel p) async {
    await _panier.ajouter(PanierItem(
      produitId: p.id,
      nom: p.nom,
      prix: double.tryParse(p.prix) ?? 0,
      image: p.image,
      vendeurId: p.vendeurId,
      vendeurNom: p.vendeurNom,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    final controller = ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    ));
    Future.delayed(const Duration(seconds: 2), () {
      try {
        controller.close();
      } catch (_) {}
    });
  }

  void _openRayon(Rayon r) {
    if (r.estPromotions) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PromotionsActivesPage()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SousRayonsPage(rayon: r)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _ctrl.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: _C.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Titre
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Center(
                child: Text('Rechercher',
                    style: GoogleFonts.sora(
                        fontSize: 18, fontWeight: FontWeight.w800, color: _C.black)),
              ),
            ),
            // ── Barre de recherche
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _buildSearchBar(hasQuery),
            ),
            // ── Corps : résultats de recherche ou liste des rayons
            Expanded(
              child: _searched ? _buildResults() : _buildRayonsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool hasQuery) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.green.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          // Icône loupe dans un badge bleu clair
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.greenLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.search_rounded, color: _C.green, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _search(),
              cursorColor: _C.green,
              style: GoogleFonts.dmSans(
                  fontSize: 14.5, color: _C.black, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Trouver un article ou une offre',
                hintStyle: GoogleFonts.dmSans(fontSize: 14, color: _C.label),
                border: InputBorder.none,
              ),
            ),
          ),
          // Bouton effacer (rond) quand on tape
          if (hasQuery)
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: _C.bg, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: _C.sub, size: 18),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Liste des rayons
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRayonsList() {
    // On masque le rayon « Promotions » (accessible via son propre onglet).
    final rayons = kRayons.where((r) => !r.estPromotions).toList();
    return ListView.separated(
      padding: const EdgeInsets.only(top: 6, bottom: 100),
      itemCount: rayons.length,
      separatorBuilder: (_, __) => const Divider(
          height: 1, thickness: 1, color: _C.divider, indent: 74, endIndent: 16),
      itemBuilder: (_, i) => _rayonTile(rayons[i]),
    );
  }

  Widget _rayonTile(Rayon r) {
    final bool promo = r.estPromotions;
    return InkWell(
      onTap: () => _openRayon(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: promo ? const Color(0xFFFDECEC) : _C.greenLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(r.icon,
                  color: promo ? const Color(0xFFE53935) : _C.green, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(r.nom,
                  style: GoogleFonts.sora(
                      fontSize: 14.5, fontWeight: FontWeight.w600, color: _C.black)),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.label),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Résultats de recherche texte
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5));
    }
    if (_error != null) {
      return _hint(_error!);
    }
    if (_produits.isEmpty && _boutiques.isEmpty) {
      return _hint('Aucun résultat');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        if (_boutiques.isNotEmpty) ...[
          _sectionTitle('Boutiques (${_boutiques.length})'),
          ..._boutiques.map(_boutiqueTile),
          const SizedBox(height: 16),
        ],
        if (_produits.isNotEmpty) ...[
          _sectionTitle('Produits (${_produits.length})'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
            ),
            itemCount: _produits.length,
            itemBuilder: (_, i) => _produitCard(_produits[i]),
          ),
        ],
      ],
    );
  }

  Widget _hint(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(msg, textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: _C.label)),
        ),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(t, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: _C.black)),
      );

  Widget _boutiqueTile(BoutiqueModel b) {
    final hasLogo = b.logo != null && b.logo!.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BoutiqueDetailPage(boutique: b)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _C.greenLight,
                borderRadius: BorderRadius.circular(12),
                image: hasLogo ? DecorationImage(image: NetworkImage(b.logo!), fit: BoxFit.cover) : null,
              ),
              child: hasLogo ? null : const Icon(Icons.storefront_rounded, color: _C.green, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _C.black)),
                  if (b.localisation.isNotEmpty)
                    Text(b.localisation, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(fontSize: 11, color: _C.label)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.label),
          ],
        ),
      ),
    );
  }

  Widget _produitCard(ProduitModel p) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                image: p.image.isNotEmpty
                    ? DecorationImage(image: NetworkImage(p.image), fit: BoxFit.cover)
                    : null,
              ),
              child: p.image.isEmpty
                  ? const Center(child: Icon(Icons.image_outlined, color: _C.label))
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: _C.black)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: p.prix, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800, color: _C.black)),
                      TextSpan(text: ' F', style: GoogleFonts.dmSans(fontSize: 10, color: _C.label)),
                    ])),
                    GestureDetector(
                      onTap: () => _addCart(p),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.add_rounded, color: _C.white, size: 18),
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

// ════════════════════════════════════════════════════════════════════════════
// Page des sous-rayons d'un rayon
// ════════════════════════════════════════════════════════════════════════════
class SousRayonsPage extends StatelessWidget {
  final Rayon rayon;
  const SousRayonsPage({super.key, required this.rayon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.white,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: _C.greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(rayon.icon, color: _C.green, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(rayon.nom,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800, color: _C.black)),
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.only(top: 6, bottom: 30),
        itemCount: rayon.sousRayons.length,
        separatorBuilder: (_, __) => const Divider(
            height: 1, thickness: 1, color: _C.divider, indent: 16, endIndent: 16),
        itemBuilder: (_, i) => _sousRayonTile(context, rayon.sousRayons[i]),
      ),
    );
  }

  Widget _sousRayonTile(BuildContext context, String nom) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategorieProduitsPage(
            titre: nom,
            icon: rayon.icon,
            sousTitre: rayon.nom,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: _C.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(nom,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w500, color: _C.sub)),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.label, size: 22),
          ],
        ),
      ),
    );
  }
}
