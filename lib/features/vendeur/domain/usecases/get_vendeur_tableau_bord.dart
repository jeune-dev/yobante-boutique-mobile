import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/vendeur_commande_model.dart';
import '../../data/models/vendeur_ventes_model.dart';
import '../repositories/vendeur_produit_repository.dart';

/// Données de l'accueil vendeur : ventes, compteurs catalogue et commandes.
class GetVendeurTableauBord {
  final VendeurProduitRepository repository;
  GetVendeurTableauBord(this.repository);

  Future<Either<Failure, VendeurVentesModel>> ventes({int jours = 30}) =>
      repository.ventes(jours: jours);

  Future<Either<Failure, Map<String, dynamic>>> statsProduits() =>
      repository.statsProduits();

  Future<Either<Failure, List<VendeurCommandeModel>>> commandes({String? statut}) =>
      repository.mesCommandes(statut: statut);

  Future<Either<Failure, VendeurCommandeModel>> commande(String id) =>
      repository.commande(id);
}
