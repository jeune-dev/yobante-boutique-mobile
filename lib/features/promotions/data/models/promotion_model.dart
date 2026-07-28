import '../../../home/data/models/produit_model.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

class PromotionModel {
  final String id;
  final String titre;
  final String description;
  final double prixPromo;
  final double? produitPrix;
  final int? produitStock;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String produitId;
  final String? produitNom;
  final String? produitImage;

  /// Remise annoncée, renvoyée par le backend mais jusque-là ignorée.
  final int pourcentageReduction;

  /// Section d'accueil de rattachement.
  final String section;

  /// Produit complet renvoyé par le backend avec la promotion.
  ///
  /// Indispensable pour commander : le panier a besoin du vendeur, que les
  /// champs `produitNom` / `produitPrix` ne portaient pas. Nul si le backend
  /// n'a pas joint le produit — la promotion reste alors consultable, sans
  /// bouton d'achat.
  final ProduitModel? produit;

  PromotionModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.prixPromo,
    this.produitPrix,
    this.produitStock,
    this.dateDebut,
    this.dateFin,
    required this.produitId,
    this.produitNom,
    this.produitImage,
    this.pourcentageReduction = 0,
    this.section = '',
    this.produit,
  });

  /// Libellé d'affichage : le titre de la promotion, à défaut le nom du produit.
  String get libelle =>
      titre.isNotEmpty ? titre : (produitNom ?? 'Produit en promotion');

  String get image => produitImage ?? '';

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    final produit = json['produit'] as Map<String, dynamic>?;
    return PromotionModel(
      id: json['id']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      prixPromo: _toDouble(json['prixPromo']),
      produitPrix: produit != null ? _toDouble(produit['prix']) : null,
      produitStock: produit != null ? (produit['stock'] as int?) : null,
      dateDebut: json['dateDebut'] != null
          ? DateTime.tryParse(json['dateDebut'].toString())
          : null,
      dateFin: json['dateFin'] != null
          ? DateTime.tryParse(json['dateFin'].toString())
          : null,
      produitId: (json['produitId'] ?? produit?['id'])?.toString() ?? '',
      produitNom: produit?['nom']?.toString(),
      // Le backend expose une galerie `images` ; `image` reste accepté.
      produitImage: (produit?['image'] ??
              (produit?['images'] is List && (produit!['images'] as List).isNotEmpty
                  ? (produit['images'] as List).first
                  : null))
          ?.toString(),
      // DECIMAL côté Postgres : Sequelize le renvoie en chaîne (« 30.00 »).
      // Un `as num?` donnerait null et afficherait 0 % de remise.
      pourcentageReduction: _toDouble(json['pourcentageReduction']).round(),
      section: json['section']?.toString() ?? '',
      produit: produit != null ? ProduitModel.fromJson(produit) : null,
    );
  }
}
