// Modèles de données pour les commandes.
//
// Miroir de ce que renvoie réellement le backend Yobante :
// `{ id, reference, statut, montantTotal, fraisLivraison, dateLivraisonSouhaitee,
//    note, motifRejet, createdAt, items: [{ …, produit }], adresse, paiement }`.

import 'adresse_model.dart';
import 'paiement_model.dart';

class LigneCommandeModel {
  final String id;
  final String? produitId;
  final String nomProduit;
  final String? imageProduit;
  final double prixUnitaire;
  final int quantite;
  final double sousTotal;

  LigneCommandeModel({
    required this.id,
    required this.produitId,
    required this.nomProduit,
    required this.imageProduit,
    required this.prixUnitaire,
    required this.quantite,
    required this.sousTotal,
  });

  factory LigneCommandeModel.fromJson(Map<String, dynamic> json) {
    // Le nom et l'image vivent dans le produit joint ; la ligne elle-même ne
    // porte que les montants et la quantité.
    final produit = json['produit'] as Map<String, dynamic>?;

    String image = (produit?['image'] ?? '').toString();
    if (image.isEmpty) {
      final images = produit?['images'];
      if (images is List && images.isNotEmpty) {
        final premiere = images.first;
        image = premiere is Map
            ? (premiere['url'] ?? '').toString()
            : premiere.toString();
      }
    }

    return LigneCommandeModel(
      id: json['id']?.toString() ?? '',
      produitId: (json['produitId'] ?? produit?['id'])?.toString(),
      nomProduit:
          (produit?['nom'] ?? json['nomProduit'] ?? 'Produit').toString(),
      imageProduit: image.isEmpty ? null : image,
      prixUnitaire: _toDouble(json['prixUnitaire']),
      quantite: _toInt(json['quantite']),
      sousTotal: _toDouble(json['sousTotal']),
    );
  }
}

class CommandeModel {
  final String id;
  final String reference;
  final String userId;
  final double fraisLivraison;
  final double montantTotal;
  final String statut;
  final String? note;
  final String? motifRejet;
  final DateTime? createdAt;

  /// Date à laquelle le client souhaite être livré, choisie à la commande.
  final DateTime? dateLivraisonSouhaitee;

  final List<LigneCommandeModel> lignes;

  /// Adresse de livraison retenue. Absente tant que le backend ne la joint pas
  /// (anciennes réponses) — l'affichage se replie alors sur un tiret.
  final AdresseModel? adresse;

  /// Règlement associé : c'est lui qui dit s'il reste quelque chose à payer.
  final PaiementModel? paiement;

  CommandeModel({
    required this.id,
    required this.reference,
    required this.userId,
    required this.fraisLivraison,
    required this.montantTotal,
    required this.statut,
    required this.lignes,
    this.note,
    this.motifRejet,
    this.createdAt,
    this.dateLivraisonSouhaitee,
    this.adresse,
    this.paiement,
  });

  /// Montant des articles seuls : le backend n'envoie que le total livraison
  /// comprise, on retire donc les frais plutôt que d'additionner les lignes
  /// (qui peuvent manquer sur une réponse allégée).
  double get montantProduits {
    final somme = lignes.fold<double>(0, (t, l) => t + l.sousTotal);
    if (somme > 0) return somme;
    return montantTotal - fraisLivraison;
  }

  int get nombreArticles => lignes.fold<int>(0, (t, l) => t + l.quantite);

  /// Mode de règlement choisi à la commande.
  String get modePaiement => paiement?.methode ?? 'cash_livraison';

  /// Vrai quand le client règle au livreur : il n'y a alors rien à payer dans
  /// l'application, et le bouton de paiement n'a pas lieu d'être.
  bool get paiementALaLivraison => modePaiement == 'cash_livraison';

  bool get estPaye => paiement?.estPaye ?? false;

  /// Un règlement en ligne reste dû tant qu'il n'a pas abouti.
  bool get resteAPayer =>
      !paiementALaLivraison && !estPaye && statut != 'annulee' && statut != 'rejetee';

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    // `items` côté backend ; `lignes` toléré pour d'anciennes réponses.
    final brutLignes = json['items'] ?? json['lignes'];
    final lignes = (brutLignes is List)
        ? brutLignes
            .map((e) => LigneCommandeModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList()
        : <LigneCommandeModel>[];

    final adresse = json['adresse'];
    final paiement = json['paiement'];

    return CommandeModel(
      id: json['id']?.toString() ?? '',
      reference: (json['reference'] ?? json['referenceCommande'] ?? '').toString(),
      userId: (json['userId'] ?? json['acheteurId'] ?? '').toString(),
      fraisLivraison: _toDouble(json['fraisLivraison']),
      montantTotal: _toDouble(json['montantTotal']),
      statut: json['statut']?.toString() ?? 'en_attente',
      note: json['note']?.toString(),
      motifRejet: json['motifRejet']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      dateLivraisonSouhaitee:
          DateTime.tryParse(json['dateLivraisonSouhaitee']?.toString() ?? ''),
      lignes: lignes,
      adresse: adresse is Map
          ? AdresseModel.fromJson(Map<String, dynamic>.from(adresse))
          : null,
      paiement: paiement is Map
          ? PaiementModel.fromJson(Map<String, dynamic>.from(paiement))
          : null,
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

/// Libellés FR des statuts, alignés sur l'énumération du backend.
const Map<String, String> kStatutCommandeLabels = {
  'en_attente': 'En attente',
  'validee': 'Validée',
  'en_preparation': 'En préparation',
  'expediee': 'Expédiée',
  'livree': 'Livrée',
  'annulee': 'Annulée',
  'rejetee': 'Rejetée',
};

/// Déroulé normal d'une commande, pour le suivi pas à pas.
const List<String> kSuiviCommande = [
  'en_attente',
  'validee',
  'en_preparation',
  'expediee',
  'livree',
];
