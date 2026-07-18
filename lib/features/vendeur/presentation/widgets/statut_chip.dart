import 'package:flutter/material.dart';

/// Palette partagée par les écrans vendeur.
class VendeurCouleurs {
  VendeurCouleurs._();

  static const bleu = Color(0xFF163A9E);
  static const bleuClair = Color(0xFFEAEEF9);
  static const or = Color(0xFFF5C518);
  static const noir = Color(0xFF1A1A1A);
  static const blanc = Color(0xFFFFFFFF);
  static const fond = Color(0xFFF5F7FB);
  static const gris = Color(0xFF6B7280);
  static const bordure = Color(0xFFDDE3EF);
  static const vert = Color(0xFF1B9C6B);
  static const orange = Color(0xFFE08700);
  static const rouge = Color(0xFFE53935);
}

/// Apparence d'un statut : libellé, couleur du texte et couleur de fond.
class _Apparence {
  final String libelle;
  final Color couleur;
  const _Apparence(this.libelle, this.couleur);
}

_Apparence _produit(String statut) {
  switch (statut) {
    case 'valide':
      return const _Apparence('Publié', VendeurCouleurs.vert);
    case 'valide_step1':
      return const _Apparence('Validation en cours', VendeurCouleurs.bleu);
    case 'rejete':
      return const _Apparence('Rejeté', VendeurCouleurs.rouge);
    case 'en_attente':
    default:
      return const _Apparence('En attente', VendeurCouleurs.orange);
  }
}

_Apparence _commande(String statut) {
  switch (statut) {
    case 'livree':
      return const _Apparence('Livrée', VendeurCouleurs.vert);
    case 'expediee':
      return const _Apparence('Expédiée', VendeurCouleurs.bleu);
    case 'en_preparation':
      return const _Apparence('En préparation', VendeurCouleurs.bleu);
    case 'validee':
      return const _Apparence('Validée', VendeurCouleurs.vert);
    case 'annulee':
      return const _Apparence('Annulée', VendeurCouleurs.rouge);
    case 'en_attente':
    default:
      return const _Apparence('En attente', VendeurCouleurs.orange);
  }
}

/// Pastille de statut, pour un produit (`type: StatutType.produit`) ou une
/// commande. Garde les mêmes couleurs partout dans l'espace vendeur.
enum StatutType { produit, commande }

class StatutChip extends StatelessWidget {
  final String statut;
  final StatutType type;
  final bool compact;

  const StatutChip({
    super.key,
    required this.statut,
    this.type = StatutType.produit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final a = type == StatutType.produit ? _produit(statut) : _commande(statut);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: a.couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        a.libelle,
        style: TextStyle(
          fontSize: compact ? 10.5 : 11.5,
          fontWeight: FontWeight.w700,
          color: a.couleur,
        ),
      ),
    );
  }
}

/// Formate un montant en FCFA avec séparateur de milliers.
String formatFcfa(num montant) {
  final entier = montant.round().toString();
  final tampon = StringBuffer();
  for (var i = 0; i < entier.length; i++) {
    if (i > 0 && (entier.length - i) % 3 == 0) tampon.write(' ');
    tampon.write(entier[i]);
  }
  return '${tampon.toString()} FCFA';
}
