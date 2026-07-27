import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../injection_container.dart';
import '../routes/app_router.dart';
import 'token_service.dart';

/// Service global de gestion des erreurs réseau
/// Redirige automatiquement vers la connexion en cas d'erreur 401 ou 500
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();

  factory ErrorHandlerService() {
    return _instance;
  }

  ErrorHandlerService._internal();

  late NavigatorState _navigatorState;

  void initialize(NavigatorState navigatorState) {
    _navigatorState = navigatorState;
  }

  /// Traite les erreurs Dio
  Future<void> handleError(DioException error) async {
    final statusCode = error.response?.statusCode;

    // 401 : Token expiré ou invalide → redirige vers connexion
    if (statusCode == 401) {
      await _handleUnauthorized();
      return;
    }

    // 500 : Erreur serveur → redirige vers connexion (sécurité)
    if (statusCode == 500) {
      await _handleServerError();
      return;
    }

    // Autres erreurs bizarre (4xx/5xx) → redirection
    if (statusCode != null && statusCode >= 400) {
      await _handleOtherError(statusCode);
    }
  }

  /// Gère les erreurs 401 (Unauthorized)
  Future<void> _handleUnauthorized() async {
    try {
      // Effacer le token et le user
      final tokenService = sl<TokenService>();
      await tokenService.clearToken();

      // Redirection vers la page de connexion
      if (_navigatorState.mounted) {
        _navigatorState.pushNamedAndRemoveUntil(
          AppRouter.loginRoute,
          (route) => false,
        );
      }
    } catch (e) {
      // Silencieusement échouer - le token est peut-être déjà effacé
    }
  }

  /// Gère les erreurs 500 (Erreur serveur)
  Future<void> _handleServerError() async {
    try {
      // Effacer le token et le user (sécurité)
      final tokenService = sl<TokenService>();
      await tokenService.clearToken();

      // Redirection vers la page de connexion
      if (_navigatorState.mounted) {
        _navigatorState.pushNamedAndRemoveUntil(
          AppRouter.loginRoute,
          (route) => false,
        );
      }
    } catch (e) {
      // Silencieusement échouer
    }
  }

  /// Gère les autres erreurs 4xx/5xx
  Future<void> _handleOtherError(int statusCode) async {
    // Pour les autres erreurs de sécurité (403, 404 si critique), effacer aussi
    if (statusCode == 403) {
      final tokenService = sl<TokenService>();
      await tokenService.clearToken();

      if (_navigatorState.mounted) {
        _navigatorState.pushNamedAndRemoveUntil(
          AppRouter.loginRoute,
          (route) => false,
        );
      }
    }
  }
}
