import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../data/models/categorie_model.dart';
import '../../data/models/vendeur_commande_model.dart';
import '../../data/models/vendeur_ventes_model.dart';
import '../entities/produit_vendeur.dart';

/// Contrat du domaine pour la gestion des produits, des commandes et du
/// tableau de bord côté vendeur.
abstract class VendeurProduitRepository {
  /// `statut` filtre sur `statutValidation` : en_attente, valide, rejete.
  Future<Either<Failure, List<ProduitVendeur>>> mesProduits({String? statut});

  Future<Either<Failure, List<CategorieModel>>> categories();

  /// Soumet une demande de publication. Le produit part en `en_attente`.
  Future<Either<Failure, void>> ajouterProduit({
    required String nom,
    required String description,
    required num prix,
    required int stockAlloue,
    required String categorieId,
    List<String> imagePaths,
  });

  Future<Either<Failure, void>> modifierProduit({
    required String id,
    String? nom,
    String? description,
    num? prix,
    int? stockAlloue,
    String? categorieId,
    List<String> imagePaths,
  });

  Future<Either<Failure, void>> supprimerProduit(String id);

  Future<Either<Failure, void>> majStock(String id, {int? stock, int? stockAlloue});

  // ── Tableau de bord ───────────────────────────────────────────────────

  Future<Either<Failure, Map<String, dynamic>>> statsProduits();

  Future<Either<Failure, VendeurVentesModel>> ventes({int jours});

  Future<Either<Failure, List<VendeurCommandeModel>>> mesCommandes({String? statut});

  Future<Either<Failure, VendeurCommandeModel>> commande(String id);
}
