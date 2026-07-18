import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/boutique_vendeur_model.dart';

abstract class BoutiqueRemoteDataSource {
  Future<BoutiqueVendeurModel> getMaBoutique();

  Future<BoutiqueVendeurModel> creerBoutique({
    required String nom,
    required String description,
    required String localisation,
    required String heureOuverture,
    required String heureFermeture,
    required String telephone,
    String? logoPath,
  });

  Future<BoutiqueVendeurModel> modifierBoutique({
    String? nom,
    String? description,
    String? localisation,
    String? heureOuverture,
    String? heureFermeture,
    String? telephone,
    String? logoPath,
  });

  Future<void> pauseBoutique();

  Future<void> reactiverBoutique();
}

class BoutiqueRemoteDataSourceImpl implements BoutiqueRemoteDataSource {
  final Dio dio;
  BoutiqueRemoteDataSourceImpl(this.dio);

  @override
  Future<BoutiqueVendeurModel> getMaBoutique() async {
    final res = await dio.get(BoutiqueEndpoints.maBoutique);
    return BoutiqueVendeurModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<BoutiqueVendeurModel> creerBoutique({
    required String nom,
    required String description,
    required String localisation,
    required String heureOuverture,
    required String heureFermeture,
    required String telephone,
    String? logoPath,
  }) async {
    final form = FormData.fromMap({
      'nom': nom,
      'description': description,
      'localisation': localisation,
      'heure_ouverture': heureOuverture,
      'heure_fermeture': heureFermeture,
      'telephone': telephone,
      if (logoPath != null) 'logo': await MultipartFile.fromFile(logoPath),
    });
    final res = await dio.post(BoutiqueEndpoints.creerBoutique, data: form);
    return BoutiqueVendeurModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<BoutiqueVendeurModel> modifierBoutique({
    String? nom,
    String? description,
    String? localisation,
    String? heureOuverture,
    String? heureFermeture,
    String? telephone,
    String? logoPath,
  }) async {
    final form = FormData.fromMap({
      if (nom != null) 'nom': nom,
      if (description != null) 'description': description,
      if (localisation != null) 'localisation': localisation,
      if (heureOuverture != null) 'heure_ouverture': heureOuverture,
      if (heureFermeture != null) 'heure_fermeture': heureFermeture,
      if (telephone != null) 'telephone': telephone,
      if (logoPath != null) 'logo': await MultipartFile.fromFile(logoPath),
    });
    final res = await dio.put(BoutiqueEndpoints.modifierBoutique, data: form);
    return BoutiqueVendeurModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> pauseBoutique() async {
    await dio.patch(BoutiqueEndpoints.pause);
  }

  @override
  Future<void> reactiverBoutique() async {
    await dio.patch(BoutiqueEndpoints.reactiver);
  }
}
