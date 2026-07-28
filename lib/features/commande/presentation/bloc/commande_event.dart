import 'package:equatable/equatable.dart';

abstract class CommandeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Acheteur : charger mes commandes
class LoadMesCommandes extends CommandeEvent {
  final String? statut;
  LoadMesCommandes({this.statut});
  @override
  List<Object?> get props => [statut];
}

/// Acheteur : créer une commande à partir du panier.
///
/// Le panier est tenu côté client (PanierService) : il est envoyé avec la
/// commande. [produitIds] limite l'envoi aux articles cochés ; nul, on prend
/// tout le panier.
class CreerCommande extends CommandeEvent {
  final String adresseId;
  final String methode; // wave | orange_money | carte | cash_livraison
  final Set<String>? produitIds;
  final String? note;

  /// Date à laquelle le client souhaite être livré. Facultative.
  final DateTime? dateLivraisonSouhaitee;

  CreerCommande({
    required this.adresseId,
    required this.methode,
    this.produitIds,
    this.note,
    this.dateLivraisonSouhaitee,
  });

  @override
  List<Object?> get props =>
      [adresseId, methode, produitIds, note, dateLivraisonSouhaitee];
}

/// Acheteur : lancer le règlement d'une commande déjà créée
class PayerCommande extends CommandeEvent {
  final String commandeId;
  PayerCommande(this.commandeId);
  @override
  List<Object?> get props => [commandeId];
}

/// Acheteur : vérifier où en est le paiement, au retour de la page du fournisseur
class VerifierPaiement extends CommandeEvent {
  final String commandeId;
  VerifierPaiement(this.commandeId);
  @override
  List<Object?> get props => [commandeId];
}

/// Acheteur : recharger une commande précise.
///
/// La fiche détail s'en sert pour suivre l'avancement décidé par
/// l'administration, sans recharger toute la liste.
class RechargerCommande extends CommandeEvent {
  final String commandeId;
  RechargerCommande(this.commandeId);
  @override
  List<Object?> get props => [commandeId];
}

/// Acheteur : annuler une commande
class AnnulerCommande extends CommandeEvent {
  final String commandeId;
  AnnulerCommande(this.commandeId);
  @override
  List<Object?> get props => [commandeId];
}
