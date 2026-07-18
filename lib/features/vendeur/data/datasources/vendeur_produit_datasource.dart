import 'package:dio/dio.dart';
import '../../../home/data/models/produit_model.dart';
import '../models/categorie_model.dart';
import '../models/vendeur_commande_model.dart';
import '../models/vendeur_ventes_model.dart';
import '../../../../core/constants/api_endpoints.dart';

/// Accès aux endpoints VENDEUR de gestion des produits (API Yobante, endpoints vendeur).
/// Le token est ajouté automatiquement par l'intercepteur du Dio partagé.
class VendeurProduitDataSource {
  final Dio dio;
  VendeurProduitDataSource(this.dio);

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      // Le backend enveloppe dans `data`, puis dans une clé nommée.
      final data = raw['data'];
      if (data is List) return data;
      if (data is Map) {
        for (final k in ['produits', 'categories', 'commandes', 'items']) {
          if (data[k] is List) return data[k] as List;
        }
      }
      for (final k in ['produits', 'categories', 'commandes', 'data', 'items', 'results']) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  /// Normalise une réponse "objet" du backend : les routes répondent
  /// `{ success, message, data: { <cle>: {...} } }`.
  Map<String, dynamic> _extractMap(dynamic raw, String cle) {
    if (raw is! Map) return const {};
    final data = raw['data'];
    if (data is Map && data[cle] is Map) {
      return Map<String, dynamic>.from(data[cle] as Map);
    }
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(raw);
  }

  Future<List<ProduitModel>> mesProduits({String? statut}) async {
    final res = await dio.get(
      VendeurProduitEndpoints.listeProduits,
      queryParameters: {if (statut != null) 'statut': statut},
    );
    return _extractList(res.data)
        .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategorieModel>> categories() async {
    final res = await dio.get(VendeurProduitEndpoints.categories);
    return _extractList(res.data)
        .map((e) => CategorieModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Soumet un produit à la validation de l'administration.
  /// `stockAlloue` est le stock que le vendeur demande à se voir allouer.
  Future<void> ajouterProduit({
    required String nom,
    required String description,
    required num prix,
    required int stockAlloue,
    required String categorieId,
    List<String> imagePaths = const [],
  }) async {
    final form = FormData.fromMap({
      'nom': nom,
      'description': description,
      'prix': prix,
      'stockAlloue': stockAlloue,
      'categorieId': categorieId,
      if (imagePaths.isNotEmpty)
        'images': [
          for (final path in imagePaths) await MultipartFile.fromFile(path),
        ],
    });
    await dio.post(VendeurProduitEndpoints.ajouterProduit, data: form);
  }

  /// Modifie un produit. Toute modification le renvoie en attente de validation.
  /// Fournir `imagePaths` remplace l'intégralité des images existantes.
  Future<void> modifierProduit({
    required String id,
    String? nom,
    String? description,
    num? prix,
    int? stockAlloue,
    String? categorieId,
    List<String> imagePaths = const [],
  }) async {
    final form = FormData.fromMap({
      if (nom != null) 'nom': nom,
      if (description != null) 'description': description,
      if (prix != null) 'prix': prix,
      if (stockAlloue != null) 'stockAlloue': stockAlloue,
      if (categorieId != null) 'categorieId': categorieId,
      if (imagePaths.isNotEmpty)
        'images': [
          for (final path in imagePaths) await MultipartFile.fromFile(path),
        ],
    });
    await dio.put(VendeurProduitEndpoints.modifierProduit(id), data: form);
  }

  Future<void> supprimerProduit(String id) async {
    await dio.delete(VendeurProduitEndpoints.supprimerProduit(id));
  }

  Future<void> majStock(String id, {int? stock, int? stockAlloue}) async {
    await dio.patch(VendeurProduitEndpoints.stock(id), data: {
      if (stock != null) 'stock': stock,
      if (stockAlloue != null) 'stockAlloue': stockAlloue,
    });
  }

  // ── Tableau de bord ───────────────────────────────────────────────────

  /// Compteurs du catalogue : total, validés, en attente, rejetés, ruptures.
  Future<Map<String, dynamic>> statsProduits() async {
    final res = await dio.get(VendeurDashboardEndpoints.statsProduits);
    return _extractMap(res.data, 'stats');
  }

  /// Agrégats de ventes : CA, unités, top produits, série journalière.
  Future<VendeurVentesModel> ventes({int jours = 30}) async {
    final res = await dio.get(
      VendeurCommandeEndpoints.ventes,
      queryParameters: {'jours': jours},
    );
    return VendeurVentesModel.fromJson(_extractMap(res.data, 'ventes'));
  }

  Future<List<VendeurCommandeModel>> mesCommandes({String? statut}) async {
    final res = await dio.get(
      VendeurCommandeEndpoints.commandes,
      queryParameters: {if (statut != null) 'statut': statut},
    );
    return _extractList(res.data)
        .map((e) => VendeurCommandeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VendeurCommandeModel> commande(String id) async {
    final res = await dio.get(VendeurCommandeEndpoints.commande(id));
    return VendeurCommandeModel.fromJson(_extractMap(res.data, 'commande'));
  }
}
