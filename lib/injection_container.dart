import 'package:yobante/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:yobante/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:yobante/features/auth/domain/repositories/auth_repository.dart';
import 'package:yobante/features/auth/domain/usecases/login_user.dart';
import 'package:yobante/features/auth/domain/usecases/register_user.dart';
import 'package:yobante/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:yobante/features/home/data/datasources/produit_remote_datasource.dart';
import 'package:yobante/features/home/data/repositories/produit_repository_impl.dart';
import 'package:yobante/features/home/presentation/bloc/produit_bloc.dart';
import 'package:yobante/features/commande/data/datasources/commande_remote_datasource.dart';
import 'package:yobante/features/commande/data/repositories/commande_repository.dart';
import 'package:yobante/features/commande/data/services/panier_service.dart';
import 'package:yobante/features/commande/presentation/bloc/commande_bloc.dart';
import 'package:yobante/features/vendeur/data/datasources/vendeur_produit_datasource.dart';
import 'package:yobante/features/vendeur/data/repositories/vendeur_produit_repository_impl.dart';
import 'package:yobante/features/vendeur/domain/repositories/vendeur_produit_repository.dart';
import 'package:yobante/features/vendeur/domain/usecases/get_mes_produits.dart';
import 'package:yobante/features/vendeur/domain/usecases/get_categories_vendeur.dart';
import 'package:yobante/features/vendeur/domain/usecases/ajouter_produit.dart';
import 'package:yobante/features/vendeur/domain/usecases/modifier_produit.dart';
import 'package:yobante/features/vendeur/domain/usecases/supprimer_produit.dart';
import 'package:yobante/features/vendeur/domain/usecases/toggle_disponibilite_produit.dart';
import 'package:yobante/features/vendeur/domain/usecases/dupliquer_produit.dart';
import 'package:yobante/features/vendeur/domain/usecases/ajouter_images_produit.dart';
import 'package:yobante/features/vendeur/domain/usecases/supprimer_image_produit.dart';
import 'package:yobante/features/vendeur/domain/usecases/get_vendeur_dashboard.dart';
import 'package:yobante/features/vendeur/presentation/bloc/vendeur_produit_bloc.dart';
import 'package:yobante/features/compte/data/datasources/compte_remote_datasource.dart';
import 'package:yobante/features/compte/data/repositories/compte_repository_impl.dart';
import 'package:yobante/features/compte/domain/repositories/compte_repository.dart';
import 'package:yobante/features/compte/domain/usecases/get_me.dart';
import 'package:yobante/features/compte/domain/usecases/modifier_profil.dart';
import 'package:yobante/features/compte/domain/usecases/change_password.dart';
import 'package:yobante/features/compte/domain/usecases/forgot_password.dart';
import 'package:yobante/features/compte/domain/usecases/reset_password.dart';
import 'package:yobante/features/compte/domain/usecases/delete_account.dart';
import 'package:yobante/features/compte/presentation/bloc/compte_bloc.dart';
import 'package:yobante/features/boutique/data/datasources/boutique_remote_datasource.dart';
import 'package:yobante/features/boutique/data/repositories/boutique_repository_impl.dart';
import 'package:yobante/features/boutique/domain/repositories/boutique_repository.dart';
import 'package:yobante/features/boutique/domain/usecases/get_ma_boutique.dart';
import 'package:yobante/features/boutique/domain/usecases/creer_boutique.dart';
import 'package:yobante/features/boutique/domain/usecases/modifier_boutique.dart';
import 'package:yobante/features/boutique/domain/usecases/pause_boutique.dart';
import 'package:yobante/features/boutique/domain/usecases/reactiver_boutique.dart';
import 'package:yobante/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:yobante/features/abonnement/data/datasources/abonnement_remote_datasource.dart';
import 'package:yobante/features/abonnement/data/repositories/abonnement_repository_impl.dart';
import 'package:yobante/features/abonnement/domain/repositories/abonnement_repository.dart';
import 'package:yobante/features/abonnement/domain/usecases/get_mon_abonnement.dart';
import 'package:yobante/features/abonnement/domain/usecases/initier_renouvellement.dart';
import 'package:yobante/features/abonnement/domain/usecases/get_historique_paiements.dart';
import 'package:yobante/features/abonnement/domain/usecases/payer.dart';
import 'package:yobante/features/abonnement/domain/usecases/get_paiement.dart';
import 'package:yobante/features/abonnement/presentation/bloc/abonnement_bloc.dart';
import 'package:yobante/features/favoris/data/datasources/favoris_remote_datasource.dart';
import 'package:yobante/features/favoris/data/repositories/favoris_repository.dart';
import 'package:yobante/features/favoris/presentation/bloc/favoris_bloc.dart';
import 'package:yobante/features/avis/data/datasources/avis_remote_datasource.dart';
import 'package:yobante/features/avis/data/repositories/avis_repository.dart';
import 'package:yobante/features/avis/presentation/bloc/avis_bloc.dart';
import 'package:yobante/features/messagerie/data/datasources/messagerie_remote_datasource.dart';
import 'package:yobante/features/messagerie/data/repositories/messagerie_repository.dart';
import 'package:yobante/features/messagerie/presentation/bloc/messagerie_bloc.dart';
import 'package:yobante/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:yobante/features/notifications/data/repositories/notifications_repository.dart';
import 'package:yobante/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:yobante/features/promotions/data/datasources/promotions_remote_datasource.dart';
import 'package:yobante/features/promotions/data/repositories/promotions_repository.dart';
import 'package:yobante/features/promotions/presentation/bloc/promotions_bloc.dart';
import 'package:yobante/features/signalements/data/datasources/signalements_remote_datasource.dart';
import 'package:yobante/features/signalements/data/repositories/signalements_repository.dart';
import 'package:yobante/features/signalements/presentation/bloc/signalements_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/token_service.dart';
import 'core/services/socket_service.dart';

// Service Locator
final sl = GetIt.instance;

// Journalisation sécurisée : on n'imprime (token, corps de requête, données)
// QU'EN DÉBOGAGE. En release, rien n'est loggué → pas de fuite de données sensibles.
void _log(Object? message) {
  if (kDebugMode) {
    // ignore: avoid_print
    print(message);
  }
}

Future<void> init() async {
  //================================================
  // INITIALISATION DES SERVICES EXTERNES
  //================================================

  // Initialisation de dotenv
  await dotenv.load(fileName: '.env');

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // SecureStorage
  sl.registerLazySingleton(() => const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  ));

  //================================================
  // CORE SERVICES
  //================================================

  // Services
  sl.registerLazySingleton(() => TokenService(secureStorage: sl()));
  sl.registerLazySingleton(() => SocketService(tokenService: sl()));

  //================================================
  // EXTERNAL - DIO HTTP CLIENT
  //================================================

  sl.registerLazySingleton(() {
    final baseUrl = dotenv.maybeGet('API_BASE_URL')?.trim();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL est manquant dans votre fichier .env. '
            'Ajoutez-le avant de lancer l\'application.',
      );
    }
    // Diagnostic : affiche l'URL réellement chargée depuis .env au démarrage.
    // (émulateur → doit être http://10.0.2.2:5000 ; localhost/127.0.0.1 = injoignable)
    print('🌐 API_BASE_URL chargé = $baseUrl');

    // Configuration améliorée de Dio
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Intercepteurs pour logging et gestion du token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Logging des requêtes
          _log('🌐 [REQUEST] ${options.method} ${options.path}');
          if (options.data != null) {
            if (options.data is FormData) {
              final formData = options.data as FormData;
              _log('📦 FormData fields:');
              formData.fields.forEach((field) {
                _log('  ${field.key}: ${field.value}');
              });
              formData.files.forEach((file) {
                _log('  ${file.key}: ${file.value.filename}');
              });
            } else {
              _log('📦 Body: ${options.data}');
            }
          }

          // Ajout du token JWT sauf pour login/register
          final path = options.path.split('?')[0].trim();
          final isAuthEndpoint = path.endsWith('/auth/login') ||
              path.endsWith('/auth/register');

          if (!isAuthEndpoint) {
            try {
              final token = await sl<TokenService>().getToken();

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
                _log('🔑 Token ajouté à la requête');
              }
            } catch (e) {
              _log('⚠️ Erreur lors de la récupération du token: $e');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _log('✅ [RESPONSE] ${response.statusCode} ${response.requestOptions.path}');
          if (response.data != null && response.data is Map) {
            _log('📥 Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          _log('❌ [ERROR] ${e.type} ${e.requestOptions.path}');
          _log('📝 Message: ${e.message}');
          if (e.response != null) {
            _log('📊 Status: ${e.response!.statusCode}');
            _log('📋 Data: ${e.response!.data}');
          }

          // ── Refresh token silencieux sur 401 ──────────────────────────────
          final reqPath = e.requestOptions.path.split('?')[0];
          final isAuthPath = reqPath.endsWith('/auth/login') ||
              reqPath.endsWith('/auth/register') ||
              reqPath.endsWith('/auth/refresh');
          final dejaRetente = e.requestOptions.extra['__retried'] == true;

          if (e.response?.statusCode == 401 && !isAuthPath && !dejaRetente) {
            try {
              final refresh = await sl<TokenService>().getRefreshToken();
              if (refresh != null && refresh.isNotEmpty) {
                // Dio "nu" (sans intercepteur) pour éviter toute récursion
                final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
                final r = await refreshDio.post('/auth/refresh',
                    data: {'refreshToken': refresh});
                final newToken =
                    (r.data is Map) ? r.data['token'] as String? : null;
                if (newToken != null && newToken.isNotEmpty) {
                  await sl<TokenService>().setToken(newToken);
                  _log('🔄 Token rafraîchi — rejeu de la requête');
                  final opts = e.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newToken';
                  opts.extra['__retried'] = true;
                  final clone = await dio.fetch(opts);
                  return handler.resolve(clone);
                }
              }
              // Refresh impossible → on déconnecte proprement
              await sl<TokenService>().clearToken();
            } catch (_) {
              await sl<TokenService>().clearToken();
            }
          }

          return handler.next(e);
        },
      ),
    );

    return dio;
  });

  //================================================
  // FEATURES - AUTHENTICATION
  //================================================

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));

  // BLoC
  sl.registerFactory(() => AuthBloc(
    loginUser: sl(),
    registerUser: sl(),
  ));

  //================================================
  // FEATURES - HOME (PRODUITS / BOUTIQUES)
  //================================================

  // Data Source (réutilise le Dio partagé configuré avec API_BASE_URL + intercepteur token)
  sl.registerLazySingleton<ProduitRemoteDataSource>(
        () => ProduitRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton(() => ProduitRepository(sl()));

  // BLoC
  sl.registerFactory(() => ProduitBloc(sl()));

  //================================================
  // FEATURES - COMMANDE / PANIER (e-commerce)
  //================================================

  // Panier local persistant (réutilise SharedPreferences)
  sl.registerLazySingleton(() => PanierService(prefs: sl()));

  // Data Source (Dio partagé)
  sl.registerLazySingleton<CommandeRemoteDataSource>(
        () => CommandeRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton(() => CommandeRepository(sl()));

  // BLoC
  sl.registerFactory(() => CommandeBloc(sl()));

  //================================================
  // FEATURES - VENDEUR (gestion produits)
  //================================================

  sl.registerLazySingleton(() => VendeurProduitDataSource(sl()));

  sl.registerLazySingleton<VendeurProduitRepository>(
        () => VendeurProduitRepositoryImpl(dataSource: sl()),
  );

  sl.registerLazySingleton(() => GetMesProduits(sl()));
  sl.registerLazySingleton(() => GetCategoriesVendeur(sl()));
  sl.registerLazySingleton(() => AjouterProduitUsecase(sl()));
  sl.registerLazySingleton(() => ModifierProduitUsecase(sl()));
  sl.registerLazySingleton(() => SupprimerProduitUsecase(sl()));
  sl.registerLazySingleton(() => ToggleDisponibiliteProduitUsecase(sl()));
  sl.registerLazySingleton(() => DupliquerProduitUsecase(sl()));
  sl.registerLazySingleton(() => AjouterImagesProduitUsecase(sl()));
  sl.registerLazySingleton(() => SupprimerImageProduitUsecase(sl()));
  sl.registerLazySingleton(() => GetVendeurDashboard(sl()));

  sl.registerFactory(() => VendeurProduitBloc(
    getMesProduits: sl(),
    supprimerProduit: sl(),
    toggleDisponibilite: sl(),
  ));

  //================================================
  // FEATURES - COMPTE (profil utilisateur connecté)
  //================================================

  sl.registerLazySingleton<CompteRemoteDataSource>(
        () => CompteRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<CompteRepository>(
        () => CompteRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetMe(sl()));
  sl.registerLazySingleton(() => ModifierProfil(sl()));
  sl.registerLazySingleton(() => ChangePassword(sl()));
  sl.registerLazySingleton(() => ForgotPassword(sl()));
  sl.registerLazySingleton(() => ResetPassword(sl()));
  sl.registerLazySingleton(() => DeleteAccount(sl()));

  sl.registerFactory(() => CompteBloc(
    getMe: sl(),
    modifierProfil: sl(),
    changePassword: sl(),
    forgotPassword: sl(),
    resetPassword: sl(),
    deleteAccount: sl(),
  ));

  //================================================
  // FEATURES - BOUTIQUE (vendeur)
  //================================================

  sl.registerLazySingleton<BoutiqueRemoteDataSource>(
        () => BoutiqueRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<BoutiqueRepository>(
        () => BoutiqueRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetMaBoutique(sl()));
  sl.registerLazySingleton(() => CreerBoutique(sl()));
  sl.registerLazySingleton(() => ModifierBoutique(sl()));
  sl.registerLazySingleton(() => PauseBoutique(sl()));
  sl.registerLazySingleton(() => ReactiverBoutique(sl()));

  sl.registerFactory(() => BoutiqueBloc(
    getMaBoutique: sl(),
    creerBoutique: sl(),
    modifierBoutique: sl(),
    pauseBoutique: sl(),
    reactiverBoutique: sl(),
  ));

  //================================================
  // FEATURES - ABONNEMENT + PAIEMENT (vendeur)
  //================================================

  sl.registerLazySingleton<AbonnementRemoteDataSource>(
        () => AbonnementRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<AbonnementRepository>(
        () => AbonnementRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetMonAbonnement(sl()));
  sl.registerLazySingleton(() => InitierRenouvellement(sl()));
  sl.registerLazySingleton(() => GetHistoriquePaiements(sl()));
  sl.registerLazySingleton(() => Payer(sl()));
  sl.registerLazySingleton(() => GetPaiement(sl()));

  sl.registerFactory(() => AbonnementBloc(
    getMonAbonnement: sl(),
    initierRenouvellement: sl(),
    getHistoriquePaiements: sl(),
    payer: sl(),
  ));

  //================================================
  // FEATURES - FAVORIS (acheteur)
  //================================================

  sl.registerLazySingleton<FavorisRemoteDataSource>(
        () => FavorisRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => FavorisRepository(sl()));
  sl.registerFactory(() => FavorisBloc(sl()));

  //================================================
  // FEATURES - AVIS (acheteur + vendeur)
  //================================================

  sl.registerLazySingleton<AvisRemoteDataSource>(
        () => AvisRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => AvisRepository(sl()));
  sl.registerFactory(() => AvisBloc(sl()));

  //================================================
  // FEATURES - MESSAGERIE (temps réel via socket + REST)
  //================================================

  sl.registerLazySingleton<MessagerieRemoteDataSource>(
        () => MessagerieRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => MessagerieRepository(sl()));
  sl.registerFactory(() => MessagerieBloc(sl()));

  //================================================
  // FEATURES - NOTIFICATIONS (temps réel via socket + REST) + device token
  //================================================

  sl.registerLazySingleton<NotificationsRemoteDataSource>(
        () => NotificationsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => NotificationsRepository(sl()));
  sl.registerFactory(() => NotificationsBloc(sl()));

  //================================================
  // FEATURES - PROMOTIONS
  //================================================

  sl.registerLazySingleton<PromotionsRemoteDataSource>(
        () => PromotionsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => PromotionsRepository(sl()));
  sl.registerFactory(() => PromotionsBloc(sl()));

  //================================================
  // FEATURES - SIGNALEMENTS
  //================================================

  sl.registerLazySingleton<SignalementsRemoteDataSource>(
        () => SignalementsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => SignalementsRepository(sl()));
  sl.registerFactory(() => SignalementsBloc(sl()));

  //================================================
  // VÉRIFICATION DES VARIABLES D'ENVIRONNEMENT
  //================================================

  _validateEnvVariables();

  // Démarre immédiatement l'écoute des changements d'authentification pour
  // (re)connecter le socket temps réel (messagerie / notifications) sans
  // attendre qu'un écran le résolve explicitement.
  sl<SocketService>();
}

void _validateEnvVariables() {
  final requiredVariables = [
    'API_BASE_URL',
    'AUTH_LOGIN_PATH',
    'AUTH_REGISTER_PATH',
  ];

  final missingVariables = <String>[];

  for (final variable in requiredVariables) {
    final value = dotenv.maybeGet(variable)?.trim();
    if (value == null || value.isEmpty) {
      missingVariables.add(variable);
    }
  }

  if (missingVariables.isNotEmpty) {
    throw StateError(
      'Les variables d\'environnement suivantes sont manquantes dans votre fichier .env:\n'
          '${missingVariables.join('\n')}\n\n'
          'Assurez-vous qu\'elles sont définies avant de lancer l\'application.',
    );
  }

  _log('✅ Toutes les variables d\'environnement sont configurées');
  _log('🌐 API Base URL: ${dotenv.get('API_BASE_URL')}');
  _log('🔑 Auth Login Path: ${dotenv.get('AUTH_LOGIN_PATH')}');
  _log('📝 Auth Register Path: ${dotenv.get('AUTH_REGISTER_PATH')}');
}