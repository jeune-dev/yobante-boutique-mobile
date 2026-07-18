import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../injection_container.dart';
import '../../features/notifications/data/repositories/notifications_repository.dart';
import 'notification_service.dart';
import 'token_service.dart';

/// Point d'entrée des messages reçus alors que l'application est fermée ou en
/// arrière-plan.
///
/// Doit être une fonction de premier niveau annotée `@pragma('vm:entry-point')` :
/// Android la réveille dans un isolat neuf, sans état de l'application.
/// Android affiche lui-même la notification à partir du bloc `notification` du
/// message : il n'y a rien à faire ici, la fonction existe pour que le plugin
/// enregistre le canal d'arrière-plan.
@pragma('vm:entry-point')
Future<void> gestionnaireMessageArrierePlan(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Notifications push (FCM).
///
/// Firebase n'est actif que si `google-services.json` a été déposé dans
/// `android/app/`. En son absence, l'initialisation échoue proprement et
/// l'application retombe sur le sondage de NotificationService : les
/// notifications restent visibles dans l'app, seul le push hors ligne manque.
class PushService {
  bool _actif = false;

  /// Vrai quand Firebase est initialisé et le jeton enregistré.
  bool get actif => _actif;

  NotificationService get _notifications => sl<NotificationService>();

  Future<void> initialiser() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Cas nominal tant que Firebase n'est pas configuré : on n'insiste pas.
      debugPrint('Firebase indisponible, push hors ligne désactivé : $e');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(gestionnaireMessageArrierePlan);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Application au premier plan : Android n'affiche rien de lui-même, on
      // pousse donc la notification via le plugin local.
      FirebaseMessaging.onMessage.listen(_surMessagePremierPlan);

      // Notification touchée alors que l'application était en arrière-plan.
      FirebaseMessaging.onMessageOpenedApp.listen(_surOuverture);

      // Application lancée depuis une notification, processus éteint.
      final initial = await messaging.getInitialMessage();
      if (initial != null) await _surOuverture(initial);

      await _enregistrerJeton(messaging);
      _actif = true;
    } catch (e) {
      debugPrint('Initialisation du push incomplète : $e');
    }
  }

  Future<void> _enregistrerJeton(FirebaseMessaging messaging) async {
    if (!await sl<TokenService>().isAuthenticated) return;

    final jeton = await messaging.getToken();
    if (jeton != null) await _envoyerJeton(jeton);

    // Le jeton est renouvelé par Firebase : sans ce réabonnement, l'appareil
    // cesse silencieusement de recevoir les notifications.
    messaging.onTokenRefresh.listen(_envoyerJeton);
  }

  Future<void> _envoyerJeton(String jeton) async {
    await sl<NotificationsRepository>().registerDeviceToken(
      token: jeton,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );
  }

  Future<void> _surMessagePremierPlan(RemoteMessage message) async {
    // Le compteur et la liste doivent refléter l'arrivée immédiatement.
    await _notifications.rafraichir();
  }

  Future<void> _surOuverture(RemoteMessage message) async {
    final id = message.data['notificationId'] ?? message.data['id'];
    if (id != null && id.toString().isNotEmpty) {
      await sl<NotificationsRepository>().marquerLue(id.toString());
    }
    await _notifications.rafraichir();
  }

  /// Retire l'appareil à la déconnexion : sans cela, l'utilisateur suivant
  /// recevrait les notifications du précédent.
  Future<void> desactiver() async {
    if (!_actif) return;
    try {
      final jeton = await FirebaseMessaging.instance.getToken();
      if (jeton != null) {
        await sl<NotificationsRepository>().unregisterDeviceToken(jeton);
      }
    } catch (e) {
      debugPrint('Désenregistrement du jeton impossible : $e');
    }
    _actif = false;
  }
}
