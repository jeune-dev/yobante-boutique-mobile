import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/app_logger.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String identifiant, String motDePasse);
  Future<AuthResponseModel> register({
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
  });

  /// Vérifie l'email via le code reçu (GET /auth/verify-email?email=&code=).
  Future<void> verifyEmail(String email, String code);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final String _loginPath;
  final String _registerPath;

  AuthRemoteDataSourceImpl({required this.dio})
      : _loginPath = _normalisePath(
    dotenv.get(
      'AUTH_LOGIN_PATH',
      fallback: '/auth/login',
    ),
  ),
        _registerPath = _normalisePath(
          dotenv.get(
            'AUTH_REGISTER_PATH',
            fallback: '/auth/register',
          ),
        );

  static String _normalisePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw StateError(
        'Les chemins AUTH_LOGIN_PATH et AUTH_REGISTER_PATH ne peuvent pas être vides.',
      );
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  @override
  Future<AuthResponseModel> login(
      String identifiant,
      String motDePasse,
      ) async {
    try {
      // Backend : POST /auth/login  body { identifiant, password }
      // (le serveur détecte email vs téléphone à partir de l'identifiant)
      final Map<String, dynamic> data = {
        'identifiant': identifiant,
        'password': motDePasse,
      };

      logDebug('📤 DATA ENVOYÉE: $data');

      final response = await dio.post(
        _loginPath,
        data: data,
      );

      return AuthResponseModel.fromJson(response.data);

    } on DioException catch (e) {
      logDebug('❌ ERROR: ${e.response?.data}');
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> register({
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
    try {
      logDebug('========== REGISTER REQUEST ==========');
      logDebug('Endpoint : $_registerPath');

      // Envoyer directement un JSON
      final data = <String, dynamic>{
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'password': mot_de_passe, // clé attendue par le backend
        // Le backend attend un objet adresse ({ rue, ville, region, pays… }),
        // pas une chaîne : on place le texte saisi dans « rue ».
        'adresse': {'rue': adresse},
        'telephone': telephone,
        'role': role, // ignoré par le backend (inscription = client)
      };

      // Champs boutique : uniquement pour un Vendeur (noms alignés sur le backend)
      if (role == 'Vendeur') {
        if (nomBoutique != null)       data['nomBoutique']       = nomBoutique;
        if (description != null)       data['description']       = description;
        if (localisation != null)      data['localisation']      = localisation;
        if (heureOuverture != null)    data['heure_ouverture']   = heureOuverture;
        if (heureFermeture != null)    data['heure_fermeture']   = heureFermeture;
        if (telephoneBoutique != null) data['telephoneBoutique'] = telephoneBoutique;
      }

      logDebug('Payload : ${data}');

      final response = await dio.post(
        _registerPath,
        data: data,
        options: Options(
          contentType: 'application/json', // <- JSON
        ),
      );

      logDebug('========== REGISTER RESPONSE ==========');
      logDebug('Status code : ${response.statusCode}');
      logDebug('Response data : ${response.data}');

      return AuthResponseModel.fromJson(response.data);

    } on DioException catch (e) {
      logDebug('========== REGISTER ERROR (DIO) ==========');
      logDebug('Message : ${e.message}');
      logDebug('Type : ${e.type}');
      logDebug('Status code : ${e.response?.statusCode}');
      logDebug('Error data : ${e.response?.data}');
      logDebug('Request path : ${e.requestOptions.path}');

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map && errorData.containsKey('message')
            ? errorData['message']
            : 'Données invalides';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          error: errorMessage,
        );
      }

      rethrow;
    } catch (e) {
      logDebug('========== REGISTER ERROR (UNKNOWN) ==========');
      logDebug('Error : $e');
      rethrow;
    }
  }

  @override
  Future<void> verifyEmail(String email, String code) async {
    try {
      await dio.get('/auth/verify-email',
          queryParameters: {'email': email, 'code': code});
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Code invalide ou expiré';
      throw Exception(msg);
    }
  }
}