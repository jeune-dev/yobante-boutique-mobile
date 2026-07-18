/// Agrégats de ventes renvoyés par `GET /vendeur/commandes/ventes`.
class VendeurVentesModel {
  final double chiffreAffaires;
  final int unitesVendues;
  final int nombreCommandes;
  final int commandesATraiter;
  final VentesPeriode periode;
  final List<TopProduit> topProduits;
  final List<VentesJour> parJour;

  const VendeurVentesModel({
    required this.chiffreAffaires,
    required this.unitesVendues,
    required this.nombreCommandes,
    required this.commandesATraiter,
    required this.periode,
    required this.topProduits,
    required this.parJour,
  });

  static double _double(dynamic v) => (v as num?)?.toDouble() ?? 0;
  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

  factory VendeurVentesModel.fromJson(Map<String, dynamic> json) {
    return VendeurVentesModel(
      chiffreAffaires: _double(json['chiffreAffaires']),
      unitesVendues: _int(json['unitesVendues']),
      nombreCommandes: _int(json['nombreCommandes']),
      commandesATraiter: _int(json['commandesATraiter']),
      periode: VentesPeriode.fromJson(
        (json['periode'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      topProduits: ((json['topProduits'] as List?) ?? const [])
          .map((e) => TopProduit.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      parJour: ((json['parJour'] as List?) ?? const [])
          .map((e) => VentesJour.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  /// État neutre affiché tant que les ventes ne sont pas chargées.
  static const vide = VendeurVentesModel(
    chiffreAffaires: 0,
    unitesVendues: 0,
    nombreCommandes: 0,
    commandesATraiter: 0,
    periode: VentesPeriode(jours: 30, chiffreAffaires: 0, unitesVendues: 0, nombreCommandes: 0),
    topProduits: [],
    parJour: [],
  );
}

class VentesPeriode {
  final int jours;
  final double chiffreAffaires;
  final int unitesVendues;
  final int nombreCommandes;

  const VentesPeriode({
    required this.jours,
    required this.chiffreAffaires,
    required this.unitesVendues,
    required this.nombreCommandes,
  });

  factory VentesPeriode.fromJson(Map<String, dynamic> json) => VentesPeriode(
        jours: VendeurVentesModel._int(json['jours']),
        chiffreAffaires: VendeurVentesModel._double(json['chiffreAffaires']),
        unitesVendues: VendeurVentesModel._int(json['unitesVendues']),
        nombreCommandes: VendeurVentesModel._int(json['nombreCommandes']),
      );
}

class TopProduit {
  final String produitId;
  final String nom;
  final int unites;
  final double chiffreAffaires;

  const TopProduit({
    required this.produitId,
    required this.nom,
    required this.unites,
    required this.chiffreAffaires,
  });

  factory TopProduit.fromJson(Map<String, dynamic> json) => TopProduit(
        produitId: json['produitId']?.toString() ?? '',
        nom: json['nom']?.toString() ?? '',
        unites: VendeurVentesModel._int(json['unites']),
        chiffreAffaires: VendeurVentesModel._double(json['chiffreAffaires']),
      );
}

class VentesJour {
  final String jour;
  final double chiffreAffaires;
  final int unites;

  const VentesJour({
    required this.jour,
    required this.chiffreAffaires,
    required this.unites,
  });

  factory VentesJour.fromJson(Map<String, dynamic> json) => VentesJour(
        jour: json['jour']?.toString() ?? '',
        chiffreAffaires: VendeurVentesModel._double(json['chiffreAffaires']),
        unites: VendeurVentesModel._int(json['unites']),
      );
}
