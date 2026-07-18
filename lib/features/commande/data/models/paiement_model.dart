/// État d'un paiement tel que renvoyé par l'API.
///
/// `urlPaiement` n'est présent que pour les méthodes en ligne : le paiement à
/// la livraison n'a rien à ouvrir.
class PaiementModel {
  final String id;
  final String methode;
  final String statut; // en_attente | succes | echoue | rembourse
  final double montant;
  final String? reference;
  final String? urlPaiement;
  final DateTime? payeAt;
  final String? statutCommande;

  const PaiementModel({
    required this.id,
    required this.methode,
    required this.statut,
    required this.montant,
    this.reference,
    this.urlPaiement,
    this.payeAt,
    this.statutCommande,
  });

  factory PaiementModel.fromJson(Map<String, dynamic> json) => PaiementModel(
        id: json['id']?.toString() ?? '',
        methode: json['methode']?.toString() ?? '',
        statut: json['statut']?.toString() ?? 'en_attente',
        montant: double.tryParse(json['montant']?.toString() ?? '') ?? 0,
        reference: json['reference']?.toString(),
        urlPaiement: json['urlPaiement']?.toString(),
        payeAt: DateTime.tryParse(json['payeAt']?.toString() ?? ''),
        statutCommande: json['statutCommande']?.toString(),
      );

  bool get estPaye => statut == 'succes';
  bool get aEchoue => statut == 'echoue';

  /// Vrai quand le client doit ouvrir une page pour finaliser son règlement.
  bool get demandeUneAction => urlPaiement != null && urlPaiement!.isNotEmpty;

  String get methodeLibelle {
    switch (methode) {
      case 'wave':
        return 'Wave';
      case 'orange_money':
        return 'Orange Money';
      case 'carte':
        return 'Carte bancaire';
      case 'cash_livraison':
        return 'À la livraison';
      default:
        return methode;
    }
  }

  String get statutLibelle {
    switch (statut) {
      case 'succes':
        return 'Payé';
      case 'echoue':
        return 'Échoué';
      case 'rembourse':
        return 'Remboursé';
      default:
        return methode == 'cash_livraison' ? 'À régler à la livraison' : 'En attente';
    }
  }
}
