import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;
  RegisterUser(this.repository);

  Future<Either<Failure, User>> call({
    required String nom,
    required String prenom,
    required String email,
    required String mot_de_passe,
    required String adresse,
    required String telephone,
    required String role,
    String? nomBoutique,
    String? description,
    String? localisation,
    String? heureOuverture,
    String? heureFermeture,
    String? telephoneBoutique,
  }) async {
    return await repository.register(
      nom: nom,
      prenom: prenom,
      email: email,
      mot_de_passe: mot_de_passe,
      adresse: adresse,
      telephone: telephone,
      role: role,
      nomBoutique: nomBoutique,
      description: description,
      localisation: localisation,
      heureOuverture: heureOuverture,
      heureFermeture: heureFermeture,
      telephoneBoutique: telephoneBoutique,
    );
  }
}