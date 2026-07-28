import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/image_cloudinary.dart';
import '../../../home/presentation/widgets/produit_card.dart';
import '../../data/models/promotion_model.dart';

class _C {
  static const green  = Color(0xFF163A9E);
  static const black  = Color(0xFF1A1A1A);
  static const white  = Color(0xFFFFFFFF);
  static const bg     = Color(0xFFF5F7FB);
  static const sub    = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
}

/// Produit en promotion, présenté comme n'importe quel produit de la boutique.
///
/// Le client commande directement depuis la liste, au prix promotionnel : la
/// promotion n'était jusqu'ici qu'une vitrine, sans chemin vers le panier.
class PromotionCard extends StatelessWidget {
  final PromotionModel promotion;

  const PromotionCard({super.key, required this.promotion});

  @override
  Widget build(BuildContext context) {
    final produit = promotion.produit;

    // Sans produit joint par le backend, il n'y a ni vendeur ni stock : la
    // promotion reste visible mais n'est pas commandable.
    if (produit == null) return _sansProduit();

    return ProduitCard(
      produit: produit,
      prixPromo: promotion.prixPromo,
      reduction: promotion.pourcentageReduction,
      etiquette: 'Promo',
    );
  }

  Widget _sansProduit() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: promotion.image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageOptimisee(promotion.image, largeur: 200),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: _C.bg),
                    errorWidget: (_, __, ___) => Container(
                      color: _C.bg,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: _C.sub),
                    ),
                  )
                : Container(
                    color: _C.bg,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: _C.sub),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  promotion.libelle,
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
                  formaterPrix(promotion.prixPromo),
                  style: GoogleFonts.sora(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _C.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
