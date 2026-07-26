import 'package:dio/dio.dart';
import '../../../../core/routes/app_router.dart';
import '../models/produit_model.dart';
import '../models/boutique_model.dart';
import '../models/rayon_model.dart';
import '../../../../features/promotions/data/models/promo_groupee_model.dart';
import '../../../../core/services/token_service.dart';
import '../../../../injection_container.dart';
import '../../../../core/connection/auth_interceptor.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/constants/api_endpoints.dart';

abstract class ProduitRemoteDataSource {
  Future<List<ProduitModel>> getProduits();
  Future<List<ProduitModel>> rechercher(String query);
  Future<List<ProduitModel>> filtrerVille(String ville);
  Future<List<BoutiqueModel>> getBoutiques();
  Future<List<ProduitModel>> getProduitsByBoutique(String boutiqueId);
  Future<String> getWhatsappUrl(String produitId);
  // Découverte (endpoints backend jusque-là inexploités)
  Future<List<ProduitModel>> getProduitsTendance();
  Future<List<BoutiqueModel>> getNouvellesBoutiques();
  Future<List<BoutiqueModel>> getBoutiquesVerifiees();
  // Recherche globale (produits + boutiques) & filtres avancés
  Future<({List<ProduitModel> produits, List<BoutiqueModel> boutiques})>
      rechercheGlobale(String q);
  Future<List<ProduitModel>> getProduitsAvecFiltres({
    String? categorieId,
    String? ville,
    num? prixMin,
    num? prixMax,
  });
  // Boutiques proches (géolocalisation)
  Future<List<BoutiqueModel>> getBoutiquesProches(double lat, double lng, {double rayon});
  // Rayons
  Future<List<RayonModel>> getRayons();
  Future<List<dynamic>> getProduitsDuRayon(String rayonId,
      {String? sousRayonId, String? search, int page = 1, int limit = 20});
  Future<List<dynamic>> getProduitsDuSousRayon(String sousRayonId,
      {String? search, int page = 1, int limit = 20});
  // Promotions groupées
  Future<PromoGroupeeModel> getPromotionsGroupees();
  // Bannières
  Future<List<dynamic>> getBannieres();
}

class ProduitRemoteDataSourceImpl implements ProduitRemoteDataSource {
  final Dio dio;

  ProduitRemoteDataSourceImpl(this.dio);

  // ─────────────────────────────────────────────
  // 🔐 Gestion centralisée erreur token
  // ─────────────────────────────────────────────
  void _handleAuthError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;

      if (data is Map && data['message'] == 'Token expiré') {
        AuthInterceptor.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRouter.loginRoute,
              (route) => false,
        );
      }

      // Bonus : gérer aussi 401
      if (e.response?.statusCode == 401) {
        AuthInterceptor.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRouter.loginRoute,
              (route) => false,
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  // 📦 Extract list helper
  // ─────────────────────────────────────────────
  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;

    if (raw is Map<String, dynamic>) {
      for (final key in [
        'produits', 'boutiques', 'data', 'content', 'items', 'results', 'list'
      ]) {
        if (raw[key] is List) {
          return raw[key] as List;
        }
      }

      // Format ApiResponse du backend : { success, message, data: { produits: [...] } }
      // → on descend d'un niveau dans « data » si c'est un objet.
      if (raw['data'] is Map<String, dynamic>) {
        return _extractList(raw['data'] as Map<String, dynamic>);
      }

      final listEntry = raw.entries.firstWhere(
            (e) => e.value is List,
        orElse: () => const MapEntry('', []),
      );

      if (listEntry.value is List) return listEntry.value as List;
    }

    throw Exception('Impossible d\'extraire une liste');
  }

  // ─────────────────────────────────────────────
  // 🔐 Token
  // ─────────────────────────────────────────────
  Future<String?> _getToken() async {
    return await sl<TokenService>().getToken();
  }

  Future<Options> _getOptions() async {
    // Consultation libre : on NE bloque PAS les lectures publiques quand il n'y
    // a pas de token (l'intercepteur du Dio partagé l'ajoute de toute façon s'il
    // existe). On l'ajoute aussi ici quand il est présent, sinon options neutres.
    final token = await _getToken();

    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  // ─────────────────────────────────────────────
  // 🛍️ Produits
  // ─────────────────────────────────────────────
  @override
  Future<List<ProduitModel>> getProduits() async {
    try {
      final response = await dio.get(
        ProduitEndpoints.listeProduits,
        options: await _getOptions(),
      );

      final data = _extractList(response.data);

      return data
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🏪 Boutiques
  // ─────────────────────────────────────────────
  @override
  Future<List<BoutiqueModel>> getBoutiques() async {
    try {
      final response = await dio.get(
        ProduitEndpoints.listeBoutiques,
        options: await _getOptions(),
      );

      final data = _extractList(response.data);

      return data
          .map((e) => BoutiqueModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🔥 Découverte : tendances / nouvelles / vérifiées
  // ─────────────────────────────────────────────
  @override
  Future<List<ProduitModel>> getProduitsTendance() async {
    try {
      final response = await dio.get(
        ProduitEndpoints.produitsTendance,
        options: await _getOptions(),
      );
      return _extractList(response.data)
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  @override
  Future<List<BoutiqueModel>> getNouvellesBoutiques() async {
    try {
      final response = await dio.get(
        ProduitEndpoints.nouvellesBoutiques,
        options: await _getOptions(),
      );
      return _extractList(response.data)
          .map((e) => BoutiqueModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  @override
  Future<List<BoutiqueModel>> getBoutiquesVerifiees() async {
    try {
      final response = await dio.get(
        ProduitEndpoints.boutiquesVerifiees,
        options: await _getOptions(),
      );
      return _extractList(response.data)
          .map((e) => BoutiqueModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🔎 Recherche globale (produits + boutiques)
  // ─────────────────────────────────────────────
  @override
  Future<({List<ProduitModel> produits, List<BoutiqueModel> boutiques})>
      rechercheGlobale(String q) async {
    try {
      final response = await dio.get(
        ProduitEndpoints.rechercheGlobale,
        queryParameters: {'search': q, 'q': q},
        options: await _getOptions(),
      );
      // Le backend renvoie les produits sous data.produits (pas de boutiques).
      final produits = _extractList(response.data)
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (produits: produits, boutiques: <BoutiqueModel>[]);
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🎛️ Filtres avancés (prix / catégorie / ville)
  // ─────────────────────────────────────────────
  @override
  Future<List<ProduitModel>> getProduitsAvecFiltres({
    String? categorieId,
    String? ville,
    num? prixMin,
    num? prixMax,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (categorieId != null && categorieId.isNotEmpty) params['categorieId'] = categorieId;
      if (ville != null && ville.isNotEmpty) params['ville'] = ville;
      if (prixMin != null) params['prixMin'] = prixMin;
      if (prixMax != null) params['prixMax'] = prixMax;
      final response = await dio.get(
        ProduitEndpoints.produitsAvecFiltres,
        queryParameters: params.isEmpty ? null : params,
        options: await _getOptions(),
      );
      return _extractList(response.data)
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 📍 Boutiques proches (géolocalisation)
  // ─────────────────────────────────────────────
  @override
  Future<List<BoutiqueModel>> getBoutiquesProches(double lat, double lng, {double rayon = 5}) async {
    try {
      final response = await dio.get(
        ProduitEndpoints.boutiquesProches,
        queryParameters: {'lat': lat, 'lng': lng, 'rayon': rayon},
        options: await _getOptions(),
      );
      return _extractList(response.data)
          .map((e) => BoutiqueModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🔍 Recherche
  // ─────────────────────────────────────────────
  @override
  Future<List<ProduitModel>> rechercher(String query) async {
    try {
      final response = await dio.get(
        ProduitEndpoints.rechercherProduitCategorie,
        queryParameters: {'search': query},
        options: await _getOptions(),
      );

      final data = _extractList(response.data);

      return data
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🏙️ Filtrer ville
  // ─────────────────────────────────────────────
  @override
  Future<List<ProduitModel>> filtrerVille(String ville) async {
    try {
      final response = await dio.get(
        ProduitEndpoints.filtrerProduitVille,
        queryParameters: {'ville': ville},
        options: await _getOptions(),
      );

      final data = _extractList(response.data);

      return data
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🏪 Produits par boutique
  // ─────────────────────────────────────────────
  @override
  Future<List<ProduitModel>> getProduitsByBoutique(String boutiqueId) async {
    try {
      final response = await dio.get(
        ProduitEndpoints.listeProduitParBoutique(boutiqueId),
        options: await _getOptions(),
      );

      final data = _extractList(
        response.data is Map ? response.data['produits'] ?? response.data : response.data,
      );

      return data
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🗂️ Rayons
  // ─────────────────────────────────────────────
  @override
  Future<List<RayonModel>> getRayons() async {
    try {
      final response = await dio.get(
        RayonEndpoints.rayons,
        options: await _getOptions(),
      );
      final data = _extractList(response.data);
      return data
          .map((e) => RayonModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getProduitsDuRayon(
    String rayonId, {
    String? sousRayonId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        RayonEndpoints.produitsDuRayon(rayonId),
        queryParameters: {
          'page': page,
          'limit': limit,
          if (sousRayonId != null) 'sousRayonId': sousRayonId,
          if (search != null) 'search': search,
        },
        options: await _getOptions(),
      );
      return _extractList(response.data);
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getProduitsDuSousRayon(
    String sousRayonId, {
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        RayonEndpoints.produitsduSousRayon(sousRayonId),
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null) 'search': search,
        },
        options: await _getOptions(),
      );
      return _extractList(response.data);
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🎯 Promotions groupées
  // ─────────────────────────────────────────────
  @override
  Future<PromoGroupeeModel> getPromotionsGroupees() async {
    try {
      final response = await dio.get(
        PromotionEndpoints.groupees,
        options: await _getOptions(),
      );
      final data = response.data;
      // Le backend peut renvoyer { success, data: { ... } } ou directement l'objet.
      final payload = (data is Map && data['data'] is Map)
          ? data['data'] as Map<String, dynamic>
          : (data is Map ? data as Map<String, dynamic> : <String, dynamic>{});
      return PromoGroupeeModel.fromJson(payload);
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 🖼️ Bannières
  // ─────────────────────────────────────────────
  @override
  Future<List<dynamic>> getBannieres() async {
    try {
      final response = await dio.get(
        BanniereEndpoints.bannieres,
        options: await _getOptions(),
      );
      return _extractList(response.data);
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // 💬 WhatsApp — contacter vendeur
  // ─────────────────────────────────────────────
  @override
  Future<String> getWhatsappUrl(String produitId) async {
    try {
      final response = await dio.get(
        ProduitEndpoints.contacterVendeurParWhatsapp(produitId),
        options: await _getOptions(),
      );

      final data = response.data;
      logDebug('📩 Réponse brute WhatsApp: $data'); // LOG complet

      if (data is Map<String, dynamic>) {
        final url = data['whatsappUrl']; // ✅ Ici on prend le bon champ
        logDebug('🔗 URL WhatsApp extraite: $url'); // LOG URL

        if (url is String && url.isNotEmpty) {
          return url;
        }
      }

      throw Exception('URL WhatsApp introuvable dans la réponse');
    } catch (e) {
      logDebug('❌ Erreur WhatsApp: $e');
      _handleAuthError(e);
      rethrow;
    }
  }
}