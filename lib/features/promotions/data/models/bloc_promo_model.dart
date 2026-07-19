/// Métadonnées d'un bloc promo (une sous-section) pilotées depuis le dashboard.
/// section ∈ { nos_promos_du_moment, a_ne_pas_rater, nos_promos_a_venir }
class BlocPromoModel {
  /// Identifie la sous-section, pour ne charger que ses produits.
  final String id;
  final String section;
  final String? titre;
  final String? sousTitre;
  final String? image;

  BlocPromoModel({
    required this.id,
    required this.section,
    this.titre,
    this.sousTitre,
    this.image,
  });

  factory BlocPromoModel.fromJson(Map<String, dynamic> json) {
    return BlocPromoModel(
      id: json['id']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      titre: json['titre']?.toString(),
      sousTitre: json['sousTitre']?.toString(),
      image: json['image']?.toString(),
    );
  }
}
