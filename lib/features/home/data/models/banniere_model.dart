/// Bannière de la section principale de l'accueil, pilotée depuis le dashboard.
class BanniereModel {
  final String id;
  final String titre;
  final String image;

  /// Lien optionnel : catégorie ou page vers laquelle mène la bannière.
  final String? lien;
  final String? categorieId;
  final int ordre;

  const BanniereModel({
    required this.id,
    required this.titre,
    required this.image,
    this.lien,
    this.categorieId,
    this.ordre = 0,
  });

  factory BanniereModel.fromJson(Map<String, dynamic> json) => BanniereModel(
        id: json['id']?.toString() ?? '',
        titre: json['titre']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        lien: json['lien']?.toString(),
        categorieId: json['categorieId']?.toString(),
        ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      );
}
