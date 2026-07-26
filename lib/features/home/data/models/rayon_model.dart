class SousRayonModel {
  final String id;
  final String nom;
  final String slug;
  final String? image;
  final bool isActive;

  const SousRayonModel({
    required this.id,
    required this.nom,
    required this.slug,
    this.image,
    required this.isActive,
  });

  factory SousRayonModel.fromJson(Map<String, dynamic> json) => SousRayonModel(
        id: json['id']?.toString() ?? '',
        nom: json['nom']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        image: json['image']?.toString(),
        isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      );
}

class RayonModel {
  final String id;
  final String nom;
  final String slug;
  final String? image;
  final bool isActive;
  final List<SousRayonModel> sousRayons;

  const RayonModel({
    required this.id,
    required this.nom,
    required this.slug,
    this.image,
    required this.isActive,
    required this.sousRayons,
  });

  factory RayonModel.fromJson(Map<String, dynamic> json) => RayonModel(
        id: json['id']?.toString() ?? '',
        nom: json['nom']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        image: json['image']?.toString(),
        isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
        sousRayons: (json['sousRayons'] as List<dynamic>? ?? [])
            .map((e) => SousRayonModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
