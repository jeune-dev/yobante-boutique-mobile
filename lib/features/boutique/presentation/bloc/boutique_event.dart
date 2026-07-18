import 'package:equatable/equatable.dart';

abstract class BoutiqueEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMaBoutique extends BoutiqueEvent {}

class CreerBoutiqueRequested extends BoutiqueEvent {
  final String nom;
  final String description;
  final String localisation;
  final String heureOuverture;
  final String heureFermeture;
  final String telephone;
  final String? logoPath;

  CreerBoutiqueRequested({
    required this.nom,
    required this.description,
    required this.localisation,
    required this.heureOuverture,
    required this.heureFermeture,
    required this.telephone,
    this.logoPath,
  });

  @override
  List<Object?> get props =>
      [nom, description, localisation, heureOuverture, heureFermeture, telephone, logoPath];
}

class ModifierBoutiqueRequested extends BoutiqueEvent {
  final String? nom;
  final String? description;
  final String? localisation;
  final String? heureOuverture;
  final String? heureFermeture;
  final String? telephone;
  final String? logoPath;

  ModifierBoutiqueRequested({
    this.nom,
    this.description,
    this.localisation,
    this.heureOuverture,
    this.heureFermeture,
    this.telephone,
    this.logoPath,
  });

  @override
  List<Object?> get props =>
      [nom, description, localisation, heureOuverture, heureFermeture, telephone, logoPath];
}

class PauseBoutiqueRequested extends BoutiqueEvent {}

class ReactiverBoutiqueRequested extends BoutiqueEvent {}
