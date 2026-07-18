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
/// Le panier est tenu côté serveur : seuls l'adresse de livraison et le mode
/// de règlement sont transmis. Le mode choisi ici détermine le fournisseur de
/// paiement utilisé ensuite.
class CreerCommande extends CommandeEvent {
  final String adresseId;
  final String methode; // wave | orange_money | carte | cash_livraison
  final String? note;

  CreerCommande({
    required this.adresseId,
    required this.methode,
    this.note,
  });

  @override
  List<Object?> get props => [adresseId, methode, note];
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

/// Acheteur : annuler une commande
class AnnulerCommande extends CommandeEvent {
  final String commandeId;
  AnnulerCommande(this.commandeId);
  @override
  List<Object?> get props => [commandeId];
}
