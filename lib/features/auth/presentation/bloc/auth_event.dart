import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String? email;
  final String? telephone;
  final String mot_de_passe;

  const LoginRequested({
    this.email,
    this.telephone,
    required this.mot_de_passe,
  });

  @override
  List<Object?> get props => [email, telephone, mot_de_passe];
}

class RegisterRequested extends AuthEvent {
  final String nom;
  final String prenom;
  final String email;
  final String mot_de_passe;
  final String adresse;
  final String telephone;
  final String role;
  // Champs boutique — renseignés uniquement pour un Vendeur (null sinon)
  final String? nomBoutique;
  final String? description;
  final String? localisation;
  final String? heureOuverture;
  final String? heureFermeture;
  final String? telephoneBoutique;

  const RegisterRequested({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.mot_de_passe,
    required this.adresse,
    required this.telephone,
    required this.role,
    this.nomBoutique,
    this.description,
    this.localisation,
    this.heureOuverture,
    this.heureFermeture,
    this.telephoneBoutique,
  });

  @override
  List<Object?> get props => [
    nom,
    prenom,
    email,
    mot_de_passe,
    adresse,
    telephone,
    role,
    nomBoutique,
    description,
    localisation,
    heureOuverture,
    heureFermeture,
    telephoneBoutique,
  ];
}

class LogoutRequested extends AuthEvent {}

class ResetAuthState extends AuthEvent {}
