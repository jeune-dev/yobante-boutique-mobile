import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../data/models/commande_model.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const sub = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
}

Color couleurStatutCommande(String statut) {
  switch (statut) {
    case 'livree':
      return _C.green;
    case 'annulee':
    case 'rejetee':
      return Colors.red;
    case 'en_livraison':
    case 'prete':
      return const Color(0xFFFF9800);
    case 'validee':
      return const Color(0xFF3B82F6);
    default:
      return _C.sub;
  }
}

class CommandeCard extends StatelessWidget {
  final CommandeModel commande;
  final VoidCallback onTap;
  const CommandeCard({super.key, required this.commande, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final couleur = couleurStatutCommande(commande.statut);
    final nbArticles =
        commande.lignes.fold<int>(0, (s, l) => s + l.quantite);
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec référence et statut
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commande.referenceCommande,
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _C.black,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: couleur.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      kStatutCommandeLabels[commande.statut] ??
                          commande.statut,
                      style: GoogleFonts.dmSans(
                        color: couleur,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _C.border),

            // Articles avec images
            if (commande.lignes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$nbArticles article(s)',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: _C.sub,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: commande.lignes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final ligne = commande.lignes[i];
                          final images = ligne.imageProduit != null
                              ? [ligne.imageProduit!]
                              : [];
                          return Stack(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  color: _C.border,
                                  border:
                                      Border.all(color: _C.border),
                                ),
                                child: images.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius
                                                .circular(10),
                                        child: CachedNetworkImage(
                                          imageUrl: images[0],
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) =>
                                              const Center(
                                            child:
                                                SizedBox(
                                              width: 20,
                                              height:
                                                  20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons
                                              .image_not_supported,
                                          color:
                                              _C.sub,
                                          size: 24,
                                        ),
                                      ),
                              ),
                              if (ligne.quantite > 1)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                    decoration:
                                        BoxDecoration(
                                      color: _C.green,
                                      borderRadius:
                                          BorderRadius
                                              .circular(8),
                                    ),
                                    child: Text(
                                      'x${ligne.quantite}',
                                      style: GoogleFonts
                                          .dmSans(
                                        fontSize: 10,
                                        color: _C.white,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: _C.border),
            ],

            // Récapitulatif montants et paiement
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sous-total',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _C.sub,
                        ),
                      ),
                      Text(
                        '${(commande.montantTotal - commande.fraisLivraison).toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Livraison',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _C.sub,
                        ),
                      ),
                      Text(
                        '${commande.fraisLivraison.toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: _C.border),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _C.black,
                        ),
                      ),
                      Text(
                        '${commande.montantTotal.toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _C.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paiement',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: _C.sub,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: commande.statutPaiement ==
                                  'paye'
                              ? const Color(0xFF10B981)
                                  .withValues(alpha: 0.1)
                              : const Color(0xFFFB923C)
                                  .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: Text(
                          commande.statutPaiement ==
                                  'paye'
                              ? 'Payé'
                              : commande.statutPaiement ==
                                      'rembourse'
                                  ? 'Remboursé'
                                  : 'En attente',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: commande
                                        .statutPaiement ==
                                    'paye'
                                ? const Color(0xFF10B981)
                                : const Color(0xFFFB923C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (commande.statut == 'rejetee' && commande.motifRejet != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFECACA),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️ Motif du rejet',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            commande.motifRejet!,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: const Color(0xFF7F1D1D),
                              height: 1.4,
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
