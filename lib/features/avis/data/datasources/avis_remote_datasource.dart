import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/avis_model.dart';

abstract class AvisRemoteDataSource {
  Future<AvisModel> creerAvis({
    required int note,
    required String commentaire,
    required String boutiqueId,
  });
  Future<List<AvisModel>> avisParBoutique(String boutiqueId);
  Future<void> supprimerAvis(String avisId);
  Future<AvisModel> modifierAvis(String id, {int? note, String? commentaire});
  Future<List<AvisModel>> mesAvis();
  Future<List<AvisModel>> avisRecus();
  Future<AvisModel> repondre(String avisId, String reponse);
}

class AvisRemoteDataSourceImpl implements AvisRemoteDataSource {
  final Dio dio;
  AvisRemoteDataSourceImpl(this.dio);

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final k in ['avis', 'data', 'items', 'results']) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  AvisModel _parseUne(dynamic data) {
    final map = (data is Map && data['avis'] is Map)
        ? data['avis'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return AvisModel.fromJson(map);
  }

  @override
  Future<AvisModel> creerAvis({
    required int note,
    required String commentaire,
    required String boutiqueId,
  }) async {
    final res = await dio.post(AvisEndpoints.avis, data: {
      'note': note,
      'commentaire': commentaire,
      'boutiqueId': boutiqueId,
    });
    return _parseUne(res.data);
  }

  @override
  Future<List<AvisModel>> avisParBoutique(String boutiqueId) async {
    final res = await dio.get(AvisEndpoints.parBoutique(boutiqueId));
    return _extractList(res.data)
        .map((e) => AvisModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> supprimerAvis(String avisId) async {
    await dio.delete(AvisEndpoints.supprimer(avisId));
  }

  @override
  Future<AvisModel> modifierAvis(String id, {int? note, String? commentaire}) async {
    final res = await dio.put(AvisEndpoints.modifier(id), data: {
      if (note != null) 'note': note,
      if (commentaire != null) 'commentaire': commentaire,
    });
    return _parseUne(res.data);
  }

  @override
  Future<List<AvisModel>> mesAvis() async {
    final res = await dio.get(AvisEndpoints.mesAvis);
    return _extractList(res.data)
        .map((e) => AvisModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AvisModel>> avisRecus() async {
    final res = await dio.get(AvisEndpoints.mesAvisRecus);
    return _extractList(res.data)
        .map((e) => AvisModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AvisModel> repondre(String avisId, String reponse) async {
    final res =
        await dio.post(AvisEndpoints.repondre(avisId), data: {'reponse': reponse});
    return _parseUne(res.data);
  }
}
