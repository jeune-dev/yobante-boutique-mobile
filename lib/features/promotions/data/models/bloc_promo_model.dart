/// Métadonnées d'un bloc promo (une par section) pilotées depuis le dashboard.
/// section ∈ { nos_promos_du_moment, a_ne_pas_rater, nos_promos_a_venir }
class BlocPromoModel {
  final String section;
  final String? titre;
  final String? sousTitre;
  final String? image;

  BlocPromoModel({
    required this.section,
    this.titre,
    this.sousTitre,
    this.image,
  });

  factory BlocPromoModel.fromJson(Map<String, dynamic> json) {
    return BlocPromoModel(
      section: json['section']?.toString() ?? '',
      titre: json['titre']?.toString(),
      sousTitre: json['sousTitre']?.toString(),
      image: json['image']?.toString(),
    );
  }
}
