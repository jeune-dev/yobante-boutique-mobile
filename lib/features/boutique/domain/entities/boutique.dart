import 'package:equatable/equatable.dart';

/// Boutique du vendeur connecté (GET/POST/PUT /vendeur/*-boutique).
class Boutique extends Equatable {
  final String id;
  final String nom;
  final String description;
  final String localisation;
  final String? telephone;
  final String? logo;
  final String? heureOuverture;
  final String? heureFermeture;
  final bool enPause;

  const Boutique({
    required this.id,
    required this.nom,
    required this.description,
    required this.localisation,
    this.telephone,
    this.logo,
    this.heureOuverture,
    this.heureFermeture,
    this.enPause = false,
  });

  @override
  List<Object?> get props => [
        id,
        nom,
        description,
        localisation,
        telephone,
        logo,
        heureOuverture,
        heureFermeture,
        enPause,
      ];
}
