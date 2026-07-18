import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../datasources/avis_remote_datasource.dart';
import '../models/avis_model.dart';

/// Repository avis — try/catch → Either<Failure, T> au-dessus du datasource.
class AvisRepository {
  final AvisRemoteDataSource remote;
  AvisRepository(this.remote);

  String _msg(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Erreur réseau';
    }
    return e.toString();
  }

  Future<Either<Failure, AvisModel>> creerAvis({
    required int note,
    required String commentaire,
    required String boutiqueId,
  }) async {
    try {
      return Right(await remote.creerAvis(
          note: note, commentaire: commentaire, boutiqueId: boutiqueId));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, List<AvisModel>>> avisParBoutique(String boutiqueId) async {
    try {
      return Right(await remote.avisParBoutique(boutiqueId));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, void>> supprimerAvis(String avisId) async {
    try {
      await remote.supprimerAvis(avisId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, AvisModel>> modifierAvis(String id,
      {int? note, String? commentaire}) async {
    try {
      return Right(await remote.modifierAvis(id, note: note, commentaire: commentaire));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, List<AvisModel>>> mesAvis() async {
    try {
      return Right(await remote.mesAvis());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, List<AvisModel>>> avisRecus() async {
    try {
      return Right(await remote.avisRecus());
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }

  Future<Either<Failure, AvisModel>> repondre(String avisId, String reponse) async {
    try {
      return Right(await remote.repondre(avisId, reponse));
    } catch (e) {
      return Left(ServerFailure(errorMessage: _msg(e)));
    }
  }
}
