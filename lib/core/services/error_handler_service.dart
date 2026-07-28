import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../injection_container.dart';
import '../routes/app_router.dart';
import '../utils/app_logger.dart';
import 'token_service.dart';

/// Service global de gestion des erreurs réseau.
///
/// Une session invalide referme la session et **rouvre la boutique en
/// visiteur** : l'application se consulte sans compte, renvoyer vers l'écran de
/// connexion enfermerait l'utilisateur sur une page dont il n'a rien à faire.
/// C'est aussi ce qui ramenait sur la connexion juste après une déconnexion —
/// le premier appel protégé de l'accueil repartait en 401.
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

    // 401 / 403 : la session ne vaut plus rien → on la referme.
    if (statusCode == 401 || statusCode == 403) {
      await _fermerSession();
      return;
    }

    // 500 : panne serveur, pas un problème d'authentification. Déconnecter
    // l'utilisateur et réinitialiser sa navigation pour une erreur passagère
    // lui ferait perdre son écran sans raison : la page appelante affiche son
    // propre état d'erreur et propose de réessayer.
    if (statusCode == 500) {
      logDebug('⚠️ Erreur serveur 500 : ${error.requestOptions.path}');
    }
  }

  /// Efface la session et ramène l'utilisateur à l'accueil hors connexion.
  ///
  /// Sans jeton, il n'y a aucune session à refermer : un visiteur reçoit
  /// naturellement des 401 sur les endpoints protégés (favoris, commandes…) et
  /// doit pouvoir continuer à parcourir la boutique sans que sa navigation
  /// soit réinitialisée.
  Future<void> _fermerSession() async {
    try {
      final tokenService = sl<TokenService>();
      if (!await tokenService.isAuthenticated) return;

      await tokenService.clearToken();

      if (_navigatorState.mounted) {
        _navigatorState.pushNamedAndRemoveUntil(
          AppRouter.acheteurRoute,
          (route) => false,
        );
      }
    } catch (_) {
      // Silencieusement : le jeton est peut-être déjà effacé.
    }
  }
}
