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
/// commande. Si vendeurId est null, on prend tous les articles, sinon
/// seulement ceux de ce vendeur.
class CreerCommande extends CommandeEvent {
  final String adresseId;
  final String methode; // wave | orange_money | carte | cash_livraison
  final String? vendeurId; // Si null, tous les articles ; sinon, seulement ceux de ce vendeur
  final String? note;

  CreerCommande({
    required this.adresseId,
    required this.methode,
    this.vendeurId,
    this.note,
  });

  @override
  List<Object?> get props => [adresseId, methode, vendeurId, note];
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
