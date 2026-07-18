class AvisModel {
  final String id;
  final int note;
  final String commentaire;
  final String? boutiqueId;
  final String? boutiqueNom;
  final String? acheteurId;
  final String? acheteurNom;
  final String? reponseVendeur;
  final DateTime? createdAt;

  AvisModel({
    required this.id,
    required this.note,
    required this.commentaire,
    this.boutiqueId,
    this.boutiqueNom,
    this.acheteurId,
    this.acheteurNom,
    this.reponseVendeur,
    this.createdAt,
  });

  factory AvisModel.fromJson(Map<String, dynamic> json) {
    final acheteur = json['acheteur'] as Map<String, dynamic>?;
    final boutique = json['boutique'] as Map<String, dynamic>?;
    return AvisModel(
      id: json['id']?.toString() ?? '',
      note: (json['note'] is int)
          ? json['note']
          : int.tryParse('${json['note']}') ?? 0,
      commentaire: json['commentaire']?.toString() ?? '',
      boutiqueId: json['boutiqueId']?.toString(),
      boutiqueNom: boutique?['nom']?.toString(),
      acheteurId: json['acheteurId']?.toString(),
      acheteurNom: acheteur != null
          ? '${acheteur['prenom'] ?? ''} ${acheteur['nom'] ?? ''}'.trim()
          : null,
      reponseVendeur: json['reponseVendeur']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
