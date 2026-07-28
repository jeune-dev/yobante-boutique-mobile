import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../data/models/commande_model.dart';

class _C {
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const sub = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
  static const bg = Color(0xFFF5F7FB);
}

Color couleurStatutCommande(String statut) {
  switch (statut) {
    case 'livree':
      return const Color(0xFF10B981);
    case 'annulee':
    case 'rejetee':
      return const Color(0xFFEF4444);
    case 'expediee':
      return const Color(0xFFF59E0B);
    case 'validee':
      return const Color(0xFF3B82F6);
    case 'en_preparation':
      return const Color(0xFF8B5CF6);
    default:
      return _C.sub;
  }
}

String _labelStatut(String statut) {
  const labels = {
    'en_attente': '⏳ En attente',
    'validee': '✓ Validée',
    'en_preparation': '📦 Préparation',
    'expediee': '🚚 Expédiée',
    'livree': '✓ Livrée',
    'annulee': '✗ Annulée',
    'rejetee': '✗ Rejetée',
  };
  return labels[statut] ?? statut;
}

class CommandeCard extends StatelessWidget {
  final CommandeModel commande;
  final VoidCallback onTap;
  const CommandeCard({super.key, required this.commande, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final couleur = couleurStatutCommande(commande.statut);
    final nbArticles = commande.nombreArticles;
    final dateFormat = DateFormat('dd MMM', 'fr_FR');
    final premiereImage = commande.lignes.isNotEmpty
        ? commande.lignes.first.imageProduit
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image principale (premier produit)
            if (premiereImage != null && premiereImage.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: premiereImage,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 160,
                        color: _C.bg,
                        child: const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 160,
                        color: _C.bg,
                        child: Icon(Icons.image_not_supported,
                            color: _C.sub, size: 32),
                      ),
                    ),
                    // Badge statut en haut à droite
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: couleur,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: couleur.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _labelStatut(commande.statut),
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.white,
                          ),
                        ),
                      ),
                    ),
                    // Badge nombre d'articles en bas à gauche
                    if (nbArticles > 1)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _C.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${nbArticles - 1}',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _C.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Référence et date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              commande.reference,
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _C.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              commande.createdAt != null
                                  ? dateFormat.format(commande.createdAt!)
                                  : '—',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: _C.sub,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Articles count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$nbArticles article${nbArticles > 1 ? 's' : ''}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _C.sub,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Prix total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _C.sub,
                        ),
                      ),
                      Text(
                        '${commande.montantTotal.toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Règlement : le libellé vient du paiement joint à la
                  // commande, seule source qui sache s'il reste à payer.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paiement',
                        style: GoogleFonts.dmSans(fontSize: 12, color: _C.sub),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: commande.estPaye
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          commande.paiement?.statutLibelle ?? 'En attente',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: commande.estPaye
                                ? const Color(0xFF059669)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Date souhaitée : c'est l'information que le client attend
                  // en priorité une fois sa commande passée.
                  if (commande.dateLivraisonSouhaitee != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Livraison souhaitée',
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: _C.sub)),
                        Text(
                          DateFormat('d MMM yyyy', 'fr_FR')
                              .format(commande.dateLivraisonSouhaitee!),
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _C.black),
                        ),
                      ],
                    ),
                  ],
                  // Motif de rejet si applicable
                  if (commande.statut == 'rejetee' &&
                      commande.motifRejet != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFFDC2626), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              commande.motifRejet!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: const Color(0xFF7F1D1D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _green = Color(0xFF163A9E);

