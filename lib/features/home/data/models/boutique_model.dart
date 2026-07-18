class BoutiqueModel {
  final String  id;
  final String  nom;
  final String  description;
  final String  localisation;
  final String? telephone;
  final String? logo;
  final String? heureOuverture;
  final String? heureFermeture;
  final String  vendeurId;
  final String  vendeurNom;
  final String  vendeurPrenom;
  final String  vendeurNumero;

  BoutiqueModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.localisation,
    this.telephone,
    this.logo,
    this.heureOuverture,
    this.heureFermeture,
    required this.vendeurId,
    required this.vendeurNom,
    required this.vendeurPrenom,
    required this.vendeurNumero,
  });

  factory BoutiqueModel.fromJson(Map<String, dynamic> json) {
    final vendeur       = json['vendeur'] as Map<String, dynamic>?;
    final vendeurId     = vendeur?['id']?.toString()     ?? '';
    final vendeurNom    = vendeur?['nom']?.toString()    ?? '';
    final vendeurPrenom = vendeur?['prenom']?.toString() ?? '';
    final vendeurNumero = vendeur?['telephone']?.toString() ?? '';

    return BoutiqueModel(
      id:             json['id']?.toString()           ?? '',
      nom:            json['nom']?.toString()           ?? '',
      description:    json['description']?.toString()   ?? '',
      localisation:   json['localisation']?.toString()  ?? '',
      telephone:      json['telephone']?.toString(),
      logo:           json['logo']?.toString(),
      heureOuverture: json['heure_ouverture']?.toString(),
      heureFermeture: json['heure_fermeture']?.toString(),
      vendeurId:      vendeurId,
      vendeurNom:     vendeurNom,
      vendeurPrenom:  vendeurPrenom,
      vendeurNumero:  vendeurNumero,
    );
  }

  String get vendeurNomComplet => '$vendeurPrenom $vendeurNom'.trim();

  // "10:00 - 20:00"
  String get horaires {
    if (heureOuverture == null || heureFermeture == null) return '';
    final open  = heureOuverture!.length >= 5
        ? heureOuverture!.substring(0, 5)
        : heureOuverture!;
    final close = heureFermeture!.length >= 5
        ? heureFermeture!.substring(0, 5)
        : heureFermeture!;
    return '$open - $close';
  }

  Map<String, dynamic> toJson() => {
    'id':              id,
    'nom':             nom,
    'description':     description,
    'localisation':    localisation,
    'telephone':       telephone,
    'logo':            logo,
    'heure_ouverture': heureOuverture,
    'heure_fermeture': heureFermeture,
    'vendeur': {
      'id':     vendeurId,
      'nom':    vendeurNom,
      'prenom': vendeurPrenom,
      'telephone': vendeurNumero,
    },
  };
}