import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/produit_vendeur.dart';
import '../../domain/repositories/vendeur_produit_repository.dart';
import '../datasources/vendeur_produit_datasource.dart';
import '../models/categorie_model.dart';
import '../models/vendeur_commande_model.dart';
import '../models/vendeur_ventes_model.dart';

class VendeurProduitRepositoryImpl implements VendeurProduitRepository {
  final VendeurProduitDataSource dataSource;
  VendeurProduitRepositoryImpl({required this.dataSource});

  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Une erreur est survenue';
    }
    return e.toString();
  }

  int? _statusCode(Object e) => e is DioException ? e.response?.statusCode : null;

  Failure _failure(Object e) =>
      ServerFailure(errorMessage: _errorMessage(e), statusCode: _statusCode(e));

  /// Enveloppe commune : évite de répéter le même try/catch sur chaque méthode.
  Future<Either<Failure, T>> _garde<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (e) {
      return Left(_failure(e));
    }
  }

  @override
  Future<Either<Failure, List<ProduitVendeur>>> mesProduits({String? statut}) =>
      _garde(() => dataSource.mesProduits(statut: statut));

  @override
  Future<Either<Failure, List<CategorieModel>>> categories() =>
      _garde(() => dataSource.categories());

  @override
  Future<Either<Failure, void>> ajouterProduit({
    required String nom,
    required String description,
    required num prix,
    required int stockAlloue,
    required String categorieId,
    List<String> imagePaths = const [],
  }) =>
      _garde(() => dataSource.ajouterProduit(
            nom: nom,
            description: description,
            prix: prix,
            stockAlloue: stockAlloue,
            categorieId: categorieId,
            imagePaths: imagePaths,
          ));

  @override
  Future<Either<Failure, void>> modifierProduit({
    required String id,
    String? nom,
    String? description,
    num? prix,
    int? stockAlloue,
    String? categorieId,
    List<String> imagePaths = const [],
  }) =>
      _garde(() => dataSource.modifierProduit(
            id: id,
            nom: nom,
            description: description,
            prix: prix,
            stockAlloue: stockAlloue,
            categorieId: categorieId,
            imagePaths: imagePaths,
          ));

  @override
  Future<Either<Failure, void>> supprimerProduit(String id) =>
      _garde(() => dataSource.supprimerProduit(id));

  @override
  Future<Either<Failure, void>> majStock(String id, {int? stock, int? stockAlloue}) =>
      _garde(() => dataSource.majStock(id, stock: stock, stockAlloue: stockAlloue));

  @override
  Future<Either<Failure, Map<String, dynamic>>> statsProduits() =>
      _garde(() => dataSource.statsProduits());

  @override
  Future<Either<Failure, VendeurVentesModel>> ventes({int jours = 30}) =>
      _garde(() => dataSource.ventes(jours: jours));

  @override
  Future<Either<Failure, List<VendeurCommandeModel>>> mesCommandes({String? statut}) =>
      _garde(() => dataSource.mesCommandes(statut: statut));

  @override
  Future<Either<Failure, VendeurCommandeModel>> commande(String id) =>
      _garde(() => dataSource.commande(id));
}
