import 'dart:async';
import 'package:yobante/core/routes/app_router.dart';
import 'package:yobante/core/theme/app_theme.dart';
import 'package:yobante/core/utils/app_logger.dart';
import 'package:yobante/features/auth/presentation/bloc/auth_bloc.dart'; // <-- IMPORT AJOUTÉ
import 'package:yobante/features/auth/presentation/pages/splash_page.dart';
import 'package:yobante/injection_container.dart' as di;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yobante/core/connection/auth_interceptor.dart';
import 'package:yobante/core/services/push_service.dart';



void main() async {
  // Capture toute erreur non interceptée (synchrone ou asynchrone) pour éviter
  // un crash silencieux en production et un écran rouge exposant la stack
  // trace à l'utilisateur final.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Erreurs du framework Flutter (build/layout/paint) : loguées en debug
    // uniquement (aucune fuite de données en production). À brancher plus tard
    // sur un service de crash reporting (Crashlytics/Sentry) si besoin.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      logDebug('💥 FlutterError: ${details.exceptionAsString()}');
    };

    // Erreurs asynchrones non capturées (hors du framework Flutter).
    PlatformDispatcher.instance.onError = (error, stack) {
      logDebug('💥 Erreur non interceptée: $error');
      return true; // empêche le crash du process
    };

    // En release, remplace l'écran rouge par défaut (qui expose la stack trace)
    // par un écran neutre pour l'utilisateur final.
    if (kReleaseMode) {
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return const Material(
          color: Colors.white,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Une erreur est survenue. Veuillez réessayer.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
            ),
          ),
        );
      };
    }

    // dotenv est chargé une seule fois, à l'intérieur de di.init().
    await di.init();

    // Push FCM : silencieux et sans effet tant que google-services.json est
    // absent. Doit précéder runApp pour capter une ouverture depuis une
    // notification alors que le processus était éteint.
    await di.sl<PushService>().initialiser();

    runApp(const MyApp());
  }, (error, stack) {
    logDebug('💥 Erreur non gérée (zone racine): $error\n$stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
      ],
      child: MaterialApp(
        navigatorKey: AuthInterceptor.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Yobante Boutique',
        theme: AppTheme.light(),
        home: const SplashPage(),
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
