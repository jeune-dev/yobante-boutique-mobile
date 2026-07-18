import 'package:equatable/equatable.dart';
import '../../data/models/commande_model.dart';
import '../../data/models/paiement_model.dart';

abstract class CommandeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CommandeInitial extends CommandeState {}

class CommandeLoading extends CommandeState {}

/// Liste de commandes de l'acheteur
class CommandesLoaded extends CommandeState {
  final List<CommandeModel> commandes;
  CommandesLoaded(this.commandes);
  @override
  List<Object?> get props => [commandes];
}

/// Une commande vient d'être créée
class CommandeCreee extends CommandeState {
  final CommandeModel commande;
  CommandeCreee(this.commande);
  @override
  List<Object?> get props => [commande];
}

/// Paiement initié. `paiement.demandeUneAction` indique s'il reste une page à
/// ouvrir : le paiement à la livraison n'en a aucune.
class PaiementInitie extends CommandeState {
  final String commandeId;
  final PaiementModel paiement;
  PaiementInitie(this.commandeId, this.paiement);
  @override
  List<Object?> get props => [commandeId, paiement.id, paiement.statut];
}

/// État du paiement après vérification auprès du serveur
class PaiementStatut extends CommandeState {
  final PaiementModel paiement;
  PaiementStatut(this.paiement);
  @override
  List<Object?> get props => [paiement.id, paiement.statut];
}

/// Une commande a été mise à jour (annulation)
class CommandeMiseAJour extends CommandeState {
  final CommandeModel commande;
  CommandeMiseAJour(this.commande);
  @override
  List<Object?> get props => [commande];
}

class CommandeError extends CommandeState {
  final String message;
  CommandeError(this.message);
  @override
  List<Object?> get props => [message];
}
