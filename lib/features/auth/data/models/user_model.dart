import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.mot_de_passe,
    required super.adresse,
    required super.telephone,
    required super.role,
    super.photoProfil,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      mot_de_passe: json['mot_de_passe'] ?? '',
      adresse: json['adresse'] ?? '',
      telephone: json['telephone'] ?? '',
      role: json['role'] ?? '',
      photoProfil: json['photoProfil'] ?? json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'mot_de_passe': mot_de_passe,
      'adresse': adresse,
      'telephone': telephone,
      'role': role,
      'photoProfil': photoProfil,
    };
  }
}

class AuthResponseModel {
  final String token;
  final String refreshToken;
  final UserModel user;

  AuthResponseModel({
    required this.token,
    this.refreshToken = '',
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Enveloppe backend : { success, message, data: { token, refreshToken, user } }
    // (compatibilité conservée avec l'ancien format plat).
    final Map<String, dynamic> root =
        (json['data'] is Map) ? Map<String, dynamic>.from(json['data']) : json;

    final userData = (root['user'] ?? root['utilisateur'] ?? {}) as Map<String, dynamic>;

    return AuthResponseModel(
      token: root['token'] ?? '',
      refreshToken: root['refreshToken'] ?? '',
      user: UserModel.fromJson(userData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'utilisateur': user.toJson(),
    };
  }
}
