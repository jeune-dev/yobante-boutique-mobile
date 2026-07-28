import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/image_cloudinary.dart';
import '../../../home/data/models/produit_model.dart';
import '../../../home/presentation/widgets/produit_card.dart' show formaterPrix;
import 'statut_chip.dart';

/// Carte d'un produit du vendeur, calquée sur la vignette vue par le client.
///
/// Le vendeur voit sa marchandise telle qu'elle apparaît en boutique — même
/// cadrage, même hiérarchie de prix — avec en plus ce qui ne le regarde que
/// lui : l'état de validation, le stock et les actions d'édition.
class CarteProduitVendeur extends StatelessWidget {
  final ProduitModel produit;

  /// Ouvre la fiche telle que le client la voit.
  final VoidCallback onTap;

  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const CarteProduitVendeur({
    super.key,
    required this.produit,
    required this.onTap,
    required this.onModifier,
    required this.onSupprimer,
  });

  bool get _enRupture => (produit.stock - produit.stockAlloue) <= 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: VendeurCouleurs.blanc,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VendeurCouleurs.bordure),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _visuel()),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                      color: VendeurCouleurs.noir,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formaterPrix(double.tryParse(produit.prix) ?? 0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: VendeurCouleurs.noir,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _piedDePage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visuel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (produit.image.isNotEmpty)
          CachedNetworkImage(
            imageUrl: imageOptimisee(produit.image, largeur: 200),
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: VendeurCouleurs.fond),
            errorWidget: (_, __, ___) => _sansVisuel(),
          )
        else
          _sansVisuel(),
        // Le statut prime sur le reste : c'est la première chose que le vendeur
        // cherche en ouvrant son catalogue.
        Positioned(
          top: 8,
          left: 8,
          child: StatutChip(statut: produit.statutValidation, compact: true),
        ),
      ],
    );
  }

  Widget _sansVisuel() => Container(
        color: VendeurCouleurs.fond,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined,
            color: VendeurCouleurs.gris),
      );

  /// Stock restant et menu d'actions, sur une seule ligne.
  Widget _piedDePage() {
    final restant = produit.stock - produit.stockAlloue;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Stock $restant',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _enRupture ? VendeurCouleurs.rouge : VendeurCouleurs.gris,
            ),
          ),
        ),
        SizedBox(
          width: 30,
          height: 28,
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            iconSize: 19,
            tooltip: 'Actions',
            onSelected: (v) => v == 'edit' ? onModifier() : onSupprimer(),
            // Pas de bascule de disponibilité : le backend ne l'expose pas.
            // Le retrait passe par « Retirer », qui désactive le produit.
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(value: 'delete', child: Text('Retirer')),
            ],
          ),
        ),
      ],
    );
  }
}
