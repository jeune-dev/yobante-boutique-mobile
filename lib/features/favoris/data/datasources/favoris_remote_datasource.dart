import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../home/data/models/boutique_model.dart';

abstract class FavorisRemoteDataSource {
  Future<void> ajouter(String boutiqueId);
  Future<void> supprimer(String boutiqueId);
  Future<List<BoutiqueModel>> mesFavoris();
}

class FavorisRemoteDataSourceImpl implements FavorisRemoteDataSource {
  final Dio dio;
  FavorisRemoteDataSourceImpl(this.dio);

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final k in ['favoris', 'boutiques', 'data', 'items', 'results']) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  @override
  Future<void> ajouter(String boutiqueId) async {
    await dio.post(FavorisEndpoints.favoris, data: {'boutiqueId': boutiqueId});
  }

  @override
  Future<void> supprimer(String boutiqueId) async {
    await dio.delete(FavorisEndpoints.parId(boutiqueId));
  }

  @override
  Future<List<BoutiqueModel>> mesFavoris() async {
    final res = await dio.get(FavorisEndpoints.favoris);
    return _extractList(res.data)
        .map((e) => BoutiqueModel.fromJson(
            (e is Map && e['boutique'] is Map ? e['boutique'] : e)
                as Map<String, dynamic>))
        .toList();
  }
}
