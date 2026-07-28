/// Adresse de livraison du client, servie par `/profile/adresses`.
///
/// La commande référence une adresse par son identifiant : il faut donc en
/// choisir une existante, pas saisir du texte libre.
class AdresseModel {
  final String id;
  final String nomComplet;
  final String telephone;
  final String rue;
  final String ville;
  final String? region;
  final String pays;
  final bool parDefaut;

  const AdresseModel({
    required this.id,
    required this.nomComplet,
    required this.telephone,
    required this.rue,
    required this.ville,
    required this.pays,
    this.region,
    this.parDefaut = false,
  });

  factory AdresseModel.fromJson(Map<String, dynamic> json) => AdresseModel(
        id: json['id']?.toString() ?? '',
        nomComplet: json['nomComplet']?.toString() ?? '',
        telephone: json['telephone']?.toString() ?? '',
        rue: json['rue']?.toString() ?? '',
        ville: json['ville']?.toString() ?? '',
        region: json['region']?.toString(),
        pays: json['pays']?.toString() ?? '',
        parDefaut: json['isDefault'] == true,
      );

  /// Résumé sur une ligne, pour la sélection au moment de commander.
  String get resume => [
        rue,
        ville,
        if (region != null && region!.isNotEmpty) region,
      ].join(', ');

  /// Adresse complète, pays compris — affichée sur la fiche de commande.
  String get adresseComplete => [
        rue,
        ville,
        if (region != null && region!.isNotEmpty) region,
        if (pays.isNotEmpty) pays,
      ].where((e) => (e ?? '').isNotEmpty).join(', ');
}
