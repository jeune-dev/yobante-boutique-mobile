import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../repositories/vendeur_produit_repository.dart';

/// Modifie un produit existant. Toute modification le renvoie en attente de
/// revalidation côté administration.
class ModifierProduitUsecase {
  final VendeurProduitRepository repository;
  ModifierProduitUsecase(this.repository);

  Future<Either<Failure, void>> call({
    required String id,
    String? nom,
    String? description,
    num? prix,
    int? stockAlloue,
    String? categorieId,
    List<String> imagePaths = const [],
  }) {
    return repository.modifierProduit(
      id: id,
      nom: nom,
      description: description,
      prix: prix,
      stockAlloue: stockAlloue,
      categorieId: categorieId,
      imagePaths: imagePaths,
    );
  }
}
