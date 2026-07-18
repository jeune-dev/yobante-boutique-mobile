import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/home/domain/entities/notification_model.dart';
import '../../features/notifications/data/repositories/notifications_repository.dart';
import '../../injection_container.dart';
import 'token_service.dart';

/// Affichage des notifications dans le bandeau système et suivi du compteur.
///
/// Deux responsabilités :
///  - pousser dans le bandeau Android les notifications reçues du backend,
///    avec le logo de l'application et le contenu du message ;
///  - tenir à jour le nombre de non-lues, exposé aux cloches de l'interface.
///
/// Les notifications restent affichées jusqu'à ce qu'on les touche ou qu'on
/// ouvre l'application : `autoCancel` les retire au clic, et `viderBandeau`
/// s'en charge à la reprise de l'app.
class NotificationService with WidgetsBindingObserver {
  static const _canalId = 'yobante_general';
  static const _canalNom = 'Notifications Yobante';

  final _plugin = FlutterLocalNotificationsPlugin();
  final _nonLues = ValueNotifier<int>(0);

  Timer? _sondage;
  bool _initialise = false;

  /// Identifiants déjà affichés, pour ne pas empiler deux fois la même
  /// notification à chaque tour de sondage.
  final Set<String> _dejaAffichees = {};

  /// Nombre de notifications non lues — écouté par les cloches.
  ValueListenable<int> get nonLues => _nonLues;

  NotificationsRepository get _repo => sl<NotificationsRepository>();

  Future<void> initialiser() async {
    if (_initialise) return;
    _initialise = true;

    // Le logo de l'application sert d'icône de notification.
    const parametresAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const parametresIos = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(android: parametresAndroid, iOS: parametresIos),
      onDidReceiveNotificationResponse: (reponse) {
        // Toucher la notification vaut prise de connaissance.
        final id = reponse.payload;
        if (id != null && id.isNotEmpty) _marquerLue(id);
      },
    );

    await _demanderPermission();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _demanderPermission() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    // Obligatoire depuis Android 13 : sans accord, rien ne s'affiche.
    await android?.requestNotificationsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Démarre le suivi. Sans compte connecté, il n'y a rien à interroger.
  Future<void> demarrer() async {
    if (!await sl<TokenService>().isAuthenticated) return;
    await initialiser();
    await rafraichir();
    _sondage?.cancel();
    // Le backend ne pousse pas encore (FCM non configuré) : on interroge
    // périodiquement tant que l'application est au premier plan.
    _sondage = Timer.periodic(const Duration(seconds: 45), (_) => rafraichir());
  }

  void arreter() {
    _sondage?.cancel();
    _sondage = null;
    _nonLues.value = 0;
    _dejaAffichees.clear();
  }

  /// Interroge le backend, met à jour le compteur et affiche les nouveautés.
  Future<void> rafraichir() async {
    final resultatCompteur = await _repo.nombreNonLues();
    resultatCompteur.fold((_) {}, (total) => _nonLues.value = total);

    if (_nonLues.value == 0) return;

    final resultatListe = await _repo.notifications();
    await resultatListe.fold(
      (_) async {},
      (notifications) async {
        // De la plus ancienne à la plus récente, pour un empilement naturel.
        final nouvelles = notifications.where((n) => !n.lue).toList().reversed;
        for (final notification in nouvelles) {
          if (_dejaAffichees.add(notification.id)) {
            await afficher(notification);
          }
        }
      },
    );
  }

  /// Pousse une notification dans le bandeau système.
  Future<void> afficher(NotificationModel notification) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _canalId,
        _canalNom,
        channelDescription: 'Commandes, paiements et validations',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        // Retirée au clic, mais pas balayable : elle reste visible tant que
        // l'utilisateur ne l'a pas ouverte.
        autoCancel: true,
        ongoing: false,
        styleInformation: BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: notification.id.hashCode,
      title: notification.titre,
      body: notification.message,
      notificationDetails: details,
      payload: notification.id,
    );
  }

  Future<void> _marquerLue(String id) async {
    await _repo.marquerLue(id);
    await rafraichir();
  }

  /// Vide le bandeau et remet le compteur à zéro : appelé quand l'utilisateur
  /// entre dans l'application, conformément au comportement attendu.
  Future<void> viderBandeau({bool marquerLues = true}) async {
    await _plugin.cancelAll();
    _dejaAffichees.clear();
    if (marquerLues) {
      await _repo.marquerToutesLues();
      _nonLues.value = 0;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Entrer dans l'application efface le bandeau, sans marquer les
      // notifications comme lues : la liste garde son intérêt.
      _plugin.cancelAll();
      _dejaAffichees.clear();
      rafraichir();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sondage?.cancel();
    _nonLues.dispose();
  }
}
