import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:yobante/core/connection/auth_interceptor.dart';
import '../../../../core/utils/image_cloudinary.dart';
import '../../../../injection_container.dart';
import '../../../commande/data/models/panier_item.dart';
import '../../../commande/data/services/panier_service.dart';
import '../../../commande/presentation/pages/panier_page.dart';
import '../../data/models/produit_model.dart';
import '../pages/acheteur/produit_detail_page.dart';

class _C {
  static const green      = Color(0xFF163A9E);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const surface    = Color(0xFFF7F9FC);
  static const border     = Color(0xFFDDE3EF);
  static const label      = Color(0xFF9AA3B2);
  static const sub        = Color(0xFF6B7280);
  static const rouge      = Color(0xFFE53E3E);
  static const or         = Color(0xFFF5C518);
}

/// Prix en francs avec séparateur de milliers : « 83 297 FCFA ».
final _francs = NumberFormat.decimalPattern('fr_FR');

String formaterPrix(double montant) => '${_francs.format(montant.round())} FCFA';

/// Rapport largeur/hauteur d'une [ProduitCard].
///
/// Il laisse la place à la ligne de prix barré et au bouton « Acheter » ;
/// l'image absorbe l'espace restant, ce qui évite tout débordement quand un nom
/// tient sur une seule ligne. Partagé par la grille et les carrousels pour que
/// la carte garde les mêmes proportions partout.
const double ratioCarteProduit = 0.56;

/// Grille produits standard : 2 colonnes, carte haute (image + infos + bouton).
const SliverGridDelegateWithFixedCrossAxisCount grilleProduits =
    SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: ratioCarteProduit,
);

/// Carte produit de la boutique.
///
/// Chaque produit est commandable directement depuis la liste : le bouton
/// « Acheter » remplit le panier sans passer par la fiche détail, qui restait
/// jusqu'ici le seul chemin possible. Le clic sur la carte ouvre toujours le
/// détail via [onTap].
class ProduitCard extends StatelessWidget {
  final ProduitModel produit;

  /// Remplace l'ouverture de la fiche produit. Laissé nul dans la quasi-totalité
  /// des cas : toucher une carte doit mener au détail du produit.
  final VoidCallback? onTap;

  /// Prix promotionnel, quand le produit est porté par une promotion.
  /// Le prix d'origine est alors barré au-dessus.
  final double? prixPromo;

  /// Remise annoncée, affichée en pastille sur l'image (0 = pas de pastille).
  final int reduction;

  /// Libellé de la pastille de gauche (« SUPER DEAL », « PROMO »…).
  final String? etiquette;

  const ProduitCard({
    super.key,
    required this.produit,
    this.onTap,
    this.prixPromo,
    this.reduction = 0,
    this.etiquette,
  });

  /// Prix réellement facturé : celui de la promotion s'il y en a une.
  double get _prixEffectif =>
      prixPromo ?? (double.tryParse(produit.prix) ?? 0);

  /// Prix d'origine, affiché barré uniquement s'il est supérieur au prix payé.
  double? get _prixBarre {
    final origine = double.tryParse(produit.prix) ?? 0;
    if (prixPromo == null || origine <= prixPromo!) return null;
    return origine;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => ouvrirFicheProduit(context, produit,
          prixPromo: prixPromo, reduction: reduction),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _visuel(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    produit.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.black,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formaterPrix(_prixEffectif),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _C.black,
                    ),
                  ),
                  // Réserve la ligne même sans promotion : toutes les cartes
                  // d'une même rangée gardent alors la même hauteur de texte.
                  SizedBox(
                    height: 15,
                    child: _prixBarre == null
                        ? null
                        : Text(
                            formaterPrix(_prixBarre!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: _C.sub,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                  ),
                  const SizedBox(height: 7),
                  _boutonAcheter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visuel(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (produit.image.isNotEmpty)
          CachedNetworkImage(
            imageUrl: imageOptimisee(produit.image, largeur: 200),
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: _C.surface),
            errorWidget: (_, __, ___) => Container(
              color: _C.surface,
              child: const Icon(Icons.image_outlined, color: _C.label),
            ),
          )
        else
          Container(
            color: _C.surface,
            child: const Icon(Icons.image_outlined, color: _C.label),
          ),
        if (etiquette != null && etiquette!.isNotEmpty)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _C.or,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                etiquette!.toUpperCase(),
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: _C.black,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        if (reduction > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _C.rouge,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '-$reduction%',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _C.white,
                ),
              ),
            ),
          ),
        // Produit retiré de la vente : la carte reste lisible mais l'achat est
        // barré, plutôt que de laisser commander un article indisponible.
        if (!produit.disponible)
          Container(
            color: Colors.white.withOpacity(0.72),
            alignment: Alignment.center,
            child: Text(
              'Indisponible',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _C.sub,
              ),
            ),
          ),
      ],
    );
  }

  Widget _boutonAcheter(BuildContext context) {
    final actif = produit.disponible;
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: ElevatedButton(
        onPressed: actif
            ? () => ajouterAuPanier(context, produit, prixPromo: prixPromo)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.green,
          foregroundColor: _C.white,
          disabledBackgroundColor: _C.border,
          disabledForegroundColor: _C.label,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(
          'Acheter',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Ouvre la fiche détaillée de [p].
void ouvrirFicheProduit(
  BuildContext context,
  ProduitModel p, {
  double? prixPromo,
  int reduction = 0,
}) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => ProduitDetailPage(
      produit: p,
      prixPromo: prixPromo,
      reduction: reduction,
    ),
  ));
}

/// Ajoute [p] au panier et propose d'aller le finaliser.
///
/// [prixPromo] l'emporte sur le prix catalogue : c'est le montant réellement
/// annoncé au client sur une promotion.
Future<void> ajouterAuPanier(
  BuildContext context,
  ProduitModel p, {
  double? prixPromo,
}) async {
  await sl<PanierService>().ajouter(PanierItem(
    produitId: p.id,
    nom: p.nom,
    prix: prixPromo ?? (double.tryParse(p.prix) ?? 0),
    image: p.image,
    vendeurId: p.vendeurId,
    // Affiché dans le panier : nom de la boutique (repli sur le vendeur).
    vendeurNom: p.boutiqueNom.trim().isNotEmpty ? p.boutiqueNom : p.vendeurNom,
  ));
  if (!context.mounted) return;

  const affichage = Duration(seconds: 3);
  final messager = ScaffoldMessenger.of(context)..clearSnackBars();

  // Confirmation discrète : un libellé court tient sur une seule ligne, à côté
  // de son action. Reprendre le nom du produit faisait déborder le bandeau sur
  // trois lignes et masquait la page.
  final bandeau = messager.showSnackBar(SnackBar(
    content: Text(
      'Ajouté au panier',
      style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w600),
    ),
    backgroundColor: _C.green,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    duration: affichage,
    action: SnackBarAction(
      label: 'Voir',
      textColor: _C.or,
      onPressed: () => AuthInterceptor.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const PanierPage()),
      ),
    ),
  ));

  // Fermeture explicite : Flutter n'arme pas de minuterie sur un bandeau qui
  // porte une action quand la navigation accessible est active (TalkBack, ou
  // certains services d'accessibilité constructeur). Le bandeau restait alors
  // affiché indéfiniment. On garde donc l'action et on ferme nous-mêmes.
  Timer(affichage, () {
    try {
      bandeau.close();
    } catch (_) {
      // Déjà refermé par l'utilisateur ou remplacé par un autre bandeau.
    }
  });
}
