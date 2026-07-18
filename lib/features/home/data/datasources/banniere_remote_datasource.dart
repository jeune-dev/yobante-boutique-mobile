import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/banniere_model.dart';

/// Bannières actives de l'accueil, définies dans le dashboard administrateur.
abstract class BanniereRemoteDataSource {
  Future<List<BanniereModel>> actives();
}

class BanniereRemoteDataSourceImpl implements BanniereRemoteDataSource {
  final Dio dio;
  BanniereRemoteDataSourceImpl(this.dio);

  @override
  Future<List<BanniereModel>> actives() async {
    final res = await dio.get(BanniereEndpoints.actives);

    // Réponse enveloppée : { success, message, data: { bannieres: [...] } }.
    final data = res.data is Map ? res.data['data'] : null;
    final brut = data is Map ? data['bannieres'] : res.data;
    if (brut is! List) return const [];

    return brut
        .map((e) => BanniereModel.fromJson(e as Map<String, dynamic>))
        .where((b) => b.image.isNotEmpty)
        .toList();
  }
}
