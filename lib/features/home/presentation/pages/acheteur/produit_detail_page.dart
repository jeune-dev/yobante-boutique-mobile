import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/utils/image_cloudinary.dart';
import '../../../../../core/widgets/barre_boutique.dart';
import '../../../../../injection_container.dart';
import '../../../../avis/presentation/pages/boutique_avis_page.dart';
import '../../../../favoris/presentation/bloc/favoris_bloc.dart';
import '../../../../favoris/presentation/bloc/favoris_event.dart';
import '../../../../favoris/presentation/bloc/favoris_state.dart';
import '../../../../signalements/presentation/pages/signaler_form_page.dart';
import '../../../data/datasources/produit_remote_datasource.dart';
import '../../../data/models/produit_model.dart';
import '../../widgets/produit_card.dart';

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
  static const rouge      = Color(0xFFE53E3E);
  static const or         = Color(0xFFF5C518);
  static const whatsapp   = Color(0xFF25D366);
}

/// Fiche d'un produit.
///
/// Remplace la feuille modale qui servait jusqu'ici de « détail » : une vraie
/// page permet la galerie, la description complète, les informations vendeur,
/// et surtout le carrousel de produits similaires en bas de page.
class ProduitDetailPage extends StatefulWidget {
  final ProduitModel produit;

  /// Prix promotionnel, quand la fiche est ouverte depuis une promotion.
  final double? prixPromo;

  /// Remise annoncée, en pourcentage (0 = aucune).
  final int reduction;

  /// La fiche sert d'aperçu au vendeur sur son propre produit.
  ///
  /// Le vendeur ne fait pas d'achat : ni panier, ni prise de contact avec
  /// lui-même, ni signalement de sa propre boutique. Les suggestions de fin de
  /// page n'ont pas lieu d'être non plus — il regarde sa marchandise, pas le
  /// catalogue des autres.
  final bool apercuVendeur;

  const ProduitDetailPage({
    super.key,
    required this.produit,
    this.prixPromo,
    this.reduction = 0,
    this.apercuVendeur = false,
  });

  @override
  State<ProduitDetailPage> createState() => _ProduitDetailPageState();
}

class _ProduitDetailPageState extends State<ProduitDetailPage> {
  late final FavorisBloc _favorisBloc;

  final _galerieCtrl = PageController();
  int _pageGalerie = 0;

  List<ProduitModel> _similaires = [];
  bool _similairesEnCours = true;

  ProduitModel get p => widget.produit;

  /// Prix réellement facturé.
  double get _prixEffectif =>
      widget.prixPromo ?? (double.tryParse(p.prix) ?? 0);

  /// Prix d'origine, barré s'il dépasse le prix payé.
  double? get _prixBarre {
    final origine = double.tryParse(p.prix) ?? 0;
    if (widget.prixPromo == null || origine <= widget.prixPromo!) return null;
    return origine;
  }

  /// Visuels du produit : la galerie du vendeur, à défaut l'image principale.
  List<String> get _images {
    final galerie = (p.images ?? [])
        .map((i) => i.url)
        .where((url) => url.isNotEmpty)
        .toList();
    if (galerie.isNotEmpty) return galerie;
    return p.image.isNotEmpty ? [p.image] : const [];
  }

  @override
  void initState() {
    super.initState();
    _favorisBloc = sl<FavorisBloc>()..add(LoadFavoris());
    if (widget.apercuVendeur) {
      _similairesEnCours = false;
    } else {
      _chargerSimilaires();
    }
  }

  @override
  void dispose() {
    _galerieCtrl.dispose();
    _favorisBloc.close();
    super.dispose();
  }

  /// Produits du même sous-rayon (à défaut du même rayon).
  ///
  /// Non bloquant : une fiche reste consultable même si la suggestion échoue.
  Future<void> _chargerSimilaires() async {
    try {
      final liste = await sl<ProduitRemoteDataSource>().getProduitsSimilaires(p);
      if (!mounted) return;
      setState(() {
        _similaires = liste;
        _similairesEnCours = false;
      });
    } catch (_) {
      if (mounted) setState(() => _similairesEnCours = false);
    }
  }

  Future<void> _contacterWhatsApp() async {
    try {
      final url = await sl<ProduitRemoteDataSource>().getWhatsappUrl(p.id);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        _message('WhatsApp n\'est pas disponible sur cet appareil');
      }
    } catch (_) {
      if (mounted) _message('Impossible de contacter le vendeur pour le moment');
    }
  }

  Future<void> _appelerVendeur() async {
    if (p.vendeurNumero.isEmpty) return;
    final uri = Uri.parse('tel:${p.vendeurNumero}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _message(String texte) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(texte),
        backgroundColor: _C.black,
        behavior: SnackBarBehavior.floating,
      ));
  }

  bool _boutiqueEstFavorite(FavorisState state) =>
      state is FavorisLoaded &&
      state.boutiques.any((b) => b.id == p.boutiqueId);

  void _basculerFavori(bool actuellementFavori) {
    if (p.boutiqueId.isEmpty) return;
    _favorisBloc.add(actuellementFavori
        ? SupprimerFavori(p.boutiqueId)
        : AjouterFavori(p.boutiqueId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FavorisBloc>.value(
      value: _favorisBloc,
      child: Scaffold(
        backgroundColor: _C.bg,
        appBar: BarreBoutique(
          titre: p.nom,
          actionsClient: !widget.apercuVendeur,
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _galerie(),
            _blocPrincipal(),
            _blocDescription(),
            _blocVendeur(),
            _blocActions(),
            _blocSimilaires(),
            const SizedBox(height: 16),
          ],
        ),
        bottomNavigationBar: widget.apercuVendeur ? null : _barreAchat(),
      ),
    );
  }

  // ── Galerie ────────────────────────────────────────────────────────────────
  Widget _galerie() {
    final images = _images;
    return Container(
      color: _C.white,
      height: 300,
      child: Stack(
        children: [
          if (images.isEmpty)
            Container(
              color: _C.surface,
              alignment: Alignment.center,
              child: const Icon(Icons.image_outlined, size: 56, color: _C.label),
            )
          else
            PageView.builder(
              controller: _galerieCtrl,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _pageGalerie = i),
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: imageOptimisee(
                  images[i],
                  largeur: MediaQuery.of(context).size.width.round(),
                ),
                fit: BoxFit.contain,
                placeholder: (_, __) => Container(color: _C.surface),
                errorWidget: (_, __, ___) => Container(
                  color: _C.surface,
                  child: const Icon(Icons.image_outlined, color: _C.label),
                ),
              ),
            ),
          if (widget.reduction > 0)
            Positioned(
              top: 14,
              left: 14,
              child: _pastille('-${widget.reduction}%', _C.rouge, _C.white),
            ),
          if (!p.disponible)
            Positioned(
              top: 14,
              right: 14,
              child: _pastille('Indisponible', _C.black, _C.white),
            ),
          // Points de pagination de la galerie.
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  final actif = i == _pageGalerie;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: actif ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: actif ? _C.green : _C.border,
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

  Widget _pastille(String texte, Color fond, Color encre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        texte,
        style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w800, color: encre),
      ),
    );
  }

  // ── Nom, prix, rattachement, stock ─────────────────────────────────────────
  Widget _blocPrincipal() {
    final stockRestant = p.stock - p.stockAlloue;

    return Container(
      width: double.infinity,
      color: _C.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.nom,
            style: GoogleFonts.sora(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _C.black,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formaterPrix(_prixEffectif),
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _C.green,
                ),
              ),
              if (_prixBarre != null) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    formaterPrix(_prixBarre!),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: _C.sub,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // Rattachement au catalogue : rayon, sous-rayon, catégorie.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (p.rayonNom.isNotEmpty) _etiquette(p.rayonNom),
              if (p.sousRayonNom.isNotEmpty) _etiquette(p.sousRayonNom),
              if (p.categorie.isNotEmpty) _etiquette(p.categorie),
            ],
          ),
          const SizedBox(height: 16),
          if (p.ville.isNotEmpty)
            _ligneInfo(Icons.location_on_outlined, 'Localisation', p.ville),
          _ligneInfo(
            Icons.inventory_2_outlined,
            'Disponibilité',
            !p.disponible
                ? 'Retiré de la vente'
                : stockRestant > 0
                    ? '$stockRestant en stock'
                    : 'Stock épuisé',
          ),
        ],
      ),
    );
  }

  Widget _etiquette(String texte) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: _C.greenLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texte,
        style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w600, color: _C.green),
      ),
    );
  }

  Widget _ligneInfo(IconData icone, String intitule, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icone, size: 16, color: _C.green),
          ),
          const SizedBox(width: 10),
          Text(
            '$intitule : ',
            style: GoogleFonts.dmSans(fontSize: 13, color: _C.label),
          ),
          Expanded(
            child: Text(
              valeur,
              style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _C.black),
            ),
          ),
        ],
      ),
    );
  }

  // ── Description ────────────────────────────────────────────────────────────
  Widget _blocDescription() {
    if (p.description.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: _C.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titreBloc('Description'),
          const SizedBox(height: 10),
          Text(
            p.description,
            style: GoogleFonts.dmSans(
                fontSize: 13.5, color: _C.sub, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── Contact ────────────────────────────────────────────────────────────────
  /// La boutique étant unique, la nommer n'apprend rien au client : ce bloc ne
  /// garde que ce dont il peut se servir — appeler, et mettre en favori.
  Widget _blocVendeur() {
    // Son propre numéro, et un cœur pour mettre sa boutique en favori : rien de
    // tout cela ne sert au vendeur qui relit sa fiche.
    if (widget.apercuVendeur) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: _C.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titreBloc('Contact'),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _C.greenLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: _C.green, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  p.vendeurNumero.isNotEmpty
                      ? p.vendeurNumero
                      : 'Contactez-nous depuis le bouton ci-dessous',
                  maxLines: 2,
                  style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _C.black),
                ),
              ),
              // Le favori porte sur la boutique, pas sur le produit : c'est la
              // règle du backend (table Favori indexée sur la boutique).
              BlocBuilder<FavorisBloc, FavorisState>(
                builder: (context, state) {
                  final favori = _boutiqueEstFavorite(state);
                  return IconButton(
                    onPressed: () => _basculerFavori(favori),
                    icon: Icon(
                      favori
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: favori ? _C.rouge : _C.label,
                    ),
                  );
                },
              ),
              if (p.vendeurNumero.isNotEmpty)
                IconButton(
                  onPressed: _appelerVendeur,
                  icon: const Icon(Icons.phone_rounded, color: _C.green),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Avis / signalement ─────────────────────────────────────────────────────
  Widget _blocActions() {
    if (p.boutiqueId.isEmpty) return const SizedBox.shrink();
    return Container(
      color: _C.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BoutiqueAvisPage(
                  boutiqueId: p.boutiqueId,
                  boutiqueNom: p.boutiqueNom.trim().isNotEmpty
                      ? p.boutiqueNom
                      : p.vendeurNom,
                ),
              )),
              icon: const Icon(Icons.star_border_rounded,
                  size: 18, color: _C.or),
              label: Text('Avis & note',
                  style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _C.black)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _C.border),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (!widget.apercuVendeur) const SizedBox(width: 10),
          if (!widget.apercuVendeur)
            OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  SignalerFormPage(type: 'boutique', cibleId: p.boutiqueId),
            )),
            icon: const Icon(Icons.flag_outlined,
                size: 18, color: Colors.redAccent),
            label: Text('Signaler',
                style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _C.border),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Produits similaires ────────────────────────────────────────────────────
  /// Carrousel horizontal, fait défiler à la main.
  ///
  /// Le voisinage vient du sous-rayon du produit, sinon de son rayon : c'est ce
  /// qui rapproche le plus deux articles dans ce catalogue.
  Widget _blocSimilaires() {
    if (widget.apercuVendeur) return const SizedBox.shrink();
    if (_similairesEnCours) {
      return Container(
        color: _C.white,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: const Center(
          child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5),
        ),
      );
    }
    if (_similaires.isEmpty) return const SizedBox.shrink();

    // Largeur de carte pensée pour en laisser dépasser une : le carrousel se
    // signale de lui-même comme faisant défiler.
    const largeurCarte = 158.0;

    return Container(
      color: _C.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                _titreBloc('Produits similaires'),
                const Spacer(),
                if (p.sousRayonNom.isNotEmpty || p.rayonNom.isNotEmpty)
                  Text(
                    p.sousRayonNom.isNotEmpty ? p.sousRayonNom : p.rayonNom,
                    style: GoogleFonts.dmSans(fontSize: 12, color: _C.label),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: largeurCarte / ratioCarteProduit,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: _similaires.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: largeurCarte,
                child: ProduitCard(produit: _similaires[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titreBloc(String texte) => Text(
        texte,
        style: GoogleFonts.sora(
            fontSize: 15.5, fontWeight: FontWeight.w800, color: _C.black),
      );

  // ── Barre d'achat fixe ─────────────────────────────────────────────────────
  Widget _barreAchat() {
    return Container(
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: _contacterWhatsApp,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _C.whatsapp,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      const Icon(Icons.chat_rounded, color: _C.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: p.disponible
                        ? () => ajouterAuPanier(context, p,
                            prixPromo: widget.prixPromo)
                        : null,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    label: Text(
                      p.disponible ? 'Ajouter au panier' : 'Indisponible',
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.green,
                      foregroundColor: _C.white,
                      disabledBackgroundColor: _C.border,
                      disabledForegroundColor: _C.label,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
