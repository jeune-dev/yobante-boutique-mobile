class PromoGroupeeModel {
  final List<dynamic> nosPromosDuMoment;
  final List<dynamic> aNesPasRater;
  final List<dynamic> nosPromosAVenir;

  const PromoGroupeeModel({
    required this.nosPromosDuMoment,
    required this.aNesPasRater,
    required this.nosPromosAVenir,
  });

  factory PromoGroupeeModel.fromJson(Map<String, dynamic> json) =>
      PromoGroupeeModel(
        nosPromosDuMoment:
            json['nos_promos_du_moment'] as List<dynamic>? ?? [],
        aNesPasRater: json['a_ne_pas_rater'] as List<dynamic>? ?? [],
        nosPromosAVenir: json['nos_promos_a_venir'] as List<dynamic>? ?? [],
      );
}
