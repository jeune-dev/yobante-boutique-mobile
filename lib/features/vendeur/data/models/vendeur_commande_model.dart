/// Commande vue par le vendeur.
///
/// Le backend ne renvoie que les lignes appartenant au vendeur courant et
/// remplace `montantTotal` (qui couvrirait les autres vendeurs) par
/// `montantVendeur`.
class VendeurCommandeModel {
  final String id;
  final String reference;
  final String statut;
  final double montantVendeur;
  final DateTime? creeLe;
  final String clientNom;
  final String? clientTelephone;
  final String? ville;
  final List<VendeurCommandeLigne> lignes;

  const VendeurCommandeModel({
    required this.id,
    required this.reference,
    required this.statut,
    required this.montantVendeur,
    required this.creeLe,
    required this.clientNom,
    required this.clientTelephone,
    required this.ville,
    required this.lignes,
  });

  factory VendeurCommandeModel.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>();
    final adresse = (json['adresse'] as Map?)?.cast<String, dynamic>();
    final nom = [user?['prenom'], user?['nom']]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(' ');

    return VendeurCommandeModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'en_attente',
      montantVendeur: (json['montantVendeur'] as num?)?.toDouble() ?? 0,
      creeLe: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      clientNom: nom.isEmpty ? 'Client' : nom,
      clientTelephone: user?['telephone']?.toString(),
      ville: adresse?['ville']?.toString(),
      lignes: ((json['items'] as List?) ?? const [])
          .map((e) => VendeurCommandeLigne.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  /// Nombre total d'articles du vendeur dans la commande.
  int get totalArticles => lignes.fold(0, (sum, l) => sum + l.quantite);

  /// Libellé lisible du statut, pour l'affichage.
  String get statutLibelle {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'validee':
        return 'Validée';
      case 'en_preparation':
        return 'En préparation';
      case 'expediee':
        return 'Expédiée';
      case 'livree':
        return 'Livrée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut;
    }
  }
}

class VendeurCommandeLigne {
  final String produitId;
  final String nom;
  final int quantite;
  final double prixUnitaire;
  final double sousTotal;
  final String? image;

  const VendeurCommandeLigne({
    required this.produitId,
    required this.nom,
    required this.quantite,
    required this.prixUnitaire,
    required this.sousTotal,
    required this.image,
  });

  factory VendeurCommandeLigne.fromJson(Map<String, dynamic> json) {
    final produit = (json['produit'] as Map?)?.cast<String, dynamic>();
    final images = produit?['images'];

    return VendeurCommandeLigne(
      produitId: produit?['id']?.toString() ?? json['produitId']?.toString() ?? '',
      nom: produit?['nom']?.toString() ?? 'Produit',
      quantite: (json['quantite'] as num?)?.toInt() ?? 0,
      prixUnitaire: double.tryParse(json['prixUnitaire']?.toString() ?? '') ?? 0,
      sousTotal: double.tryParse(json['sousTotal']?.toString() ?? '') ?? 0,
      image: (images is List && images.isNotEmpty) ? images.first.toString() : null,
    );
  }
}
