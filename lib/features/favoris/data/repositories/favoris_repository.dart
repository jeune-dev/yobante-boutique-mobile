import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../home/data/models/boutique_model.dart';
import '../datasources/favoris_remote_datasource.dart';

/// Repository favoris — try/catch → Either<Failure, T> au-dessus du datasource.
class FavorisRepository {
  final FavorisRemoteDataSource remote;
  FavorisRepository(this.remote);

  String _msg(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Erreur réseau';
    }
    return e.toString();
  }

  Future<Either<Failure, void>> ajouter(String boutiqueId) async {
    try {
      await remote.ajouter(boutiqueId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, void>> supprimer(String boutiqueId) async {
    try {
      await remote.supprimer(boutiqueId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, List<BoutiqueModel>>> mesFavoris() async {
    try {
      return Right(await remote.mesFavoris());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }
}
