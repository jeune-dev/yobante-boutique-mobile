import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  final FlutterSecureStorage secureStorage;
  final StreamController<bool> _authController =
  StreamController<bool>.broadcast();

  TokenService({required this.secureStorage});

  Stream<bool> get authChanges => _authController.stream;

  /// Dernier état connu de la session, lisible **sans attendre**.
  ///
  /// Le jeton vit dans le stockage sécurisé, dont la lecture est asynchrone :
  /// un écran qui l'interroge à sa construction s'affiche donc d'abord en
  /// visiteur, puis bascule. Ce cache permet de peindre la bonne interface dès
  /// la première image. Amorcé par [initialiser] au démarrage, puis tenu à jour
  /// par [setToken] et [clearToken].
  bool _connecte = false;
  bool get estConnecte => _connecte;

  /// Amorce le cache. À appeler une fois, avant le premier écran.
  Future<bool> initialiser() async => isAuthenticated;

  Future<bool> get isAuthenticated async {
    final token = await getToken();
    _connecte = token != null && token.isNotEmpty;
    return _connecte;
  }

  Future<String?> getToken() async {
    return await secureStorage.read(key: 'jwt_token');
  }

  Future<void> setToken(String? token) async {
    if (token == null || token.isEmpty) {
      await secureStorage.delete(key: 'jwt_token');
    } else {
      await secureStorage.write(key: 'jwt_token', value: token);
    }
    final auth = await isAuthenticated;
    _authController.add(auth);
  }

  // ── Refresh token ───────────────────────────────────────────────────────
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: 'refresh_token');
  }

  Future<void> setRefreshToken(String? token) async {
    if (token == null || token.isEmpty) {
      await secureStorage.delete(key: 'refresh_token');
    } else {
      await secureStorage.write(key: 'refresh_token', value: token);
    }
  }

  Future<void> clearToken() async {
    await secureStorage.delete(key: 'jwt_token');
    await secureStorage.delete(key: 'refresh_token');
    _connecte = false;
    _authController.add(false);
  }

  void dispose() {
    _authController.close();
  }
}
