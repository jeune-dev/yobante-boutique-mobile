import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/vendeur_produit_repository.dart';

/// Demande de publication d'un produit : le produit est créé en attente de
/// validation par l'administration.
class AjouterProduitUsecase {
  final VendeurProduitRepository repository;
  AjouterProduitUsecase(this.repository);

  Future<Either<Failure, void>> call({
    required String nom,
    required String description,
    required num prix,
    required int stockAlloue,
    required String categorieId,
    List<String> imagePaths = const [],
  }) {
    return repository.ajouterProduit(
      nom: nom,
      description: description,
      prix: prix,
      stockAlloue: stockAlloue,
      categorieId: categorieId,
      imagePaths: imagePaths,
    );
  }
}
