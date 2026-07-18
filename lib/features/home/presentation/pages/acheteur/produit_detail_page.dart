import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yobante/core/connection/auth_interceptor.dart';

import '../../../../../injection_container.dart';
import '../../../data/models/produit_model.dart';
import '../../../../commande/data/services/panier_service.dart';
import '../../../../commande/data/models/panier_item.dart';
import '../../../../commande/presentation/pages/panier_page.dart';

class _C {
  static const green   = Color(0xFF163A9E);
  static const black   = Color(0xFF1A1A1A);
  static const white   = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F9FC);
  static const border  = Color(0xFFDDE3EF);
  static const label   = Color(0xFF9AA3B2);
}

// ══════════════════════════════════════════════════════════════════════════════
// Carte produit réutilisable (accueil, boutique, ma boutique) — image + nom +
// nom du restaurant + prix + un seul bouton "+" pour ajouter au panier.
// Le clic sur la carte ouvre le détail (géré par l'appelant via [onTap]).
// ══════════════════════════════════════════════════════════════════════════════
class ProduitGridCard extends StatelessWidget {
  final ProduitModel produit;
  final VoidCallback onTap;
  final VoidCallback? onAdd; // null → pas de bouton "+"

  const ProduitGridCard({
    super.key,
    required this.produit,
    required this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final p = produit;
    final nomBoutique = p.boutiqueNom.trim().isNotEmpty ? p.boutiqueNom : p.vendeurNom;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    ? const Center(child: Icon(Icons.restaurant_rounded, size: 40, color: _C.label))
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nom,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: _C.black)),
                  const SizedBox(height: 2),
                  if (nomBoutique.trim().isNotEmpty)
                    Row(children: [
                      const Icon(Icons.storefront_rounded, size: 11, color: _C.green),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(nomBoutique,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(fontSize: 10, color: _C.green, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(text: TextSpan(children: [
                        TextSpan(text: p.prix, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800, color: _C.black)),
                        TextSpan(text: ' F', style: GoogleFonts.dmSans(fontSize: 10, color: _C.label)),
                      ])),
                      if (onAdd != null)
                        GestureDetector(
                          onTap: onAdd,
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
      ),
    );
  }
}

/// Ajoute un produit au panier + snackbar (réutilisable).
Future<void> ajouterProduitAuPanier(BuildContext context, ProduitModel p) async {
  await sl<PanierService>().ajouter(PanierItem(
    produitId: p.id,
    nom: p.nom,
    prix: double.tryParse(p.prix) ?? 0,
    image: p.image,
    vendeurId: p.vendeurId,
    // Affiché dans le panier : nom de la boutique (repli sur le vendeur).
    vendeurNom: p.boutiqueNom.trim().isNotEmpty ? p.boutiqueNom : p.vendeurNom,
  ));
  if (!context.mounted) return;
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
