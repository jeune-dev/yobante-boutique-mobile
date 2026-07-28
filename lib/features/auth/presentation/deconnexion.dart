import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/connection/auth_interceptor.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/token_service.dart';
import '../../../injection_container.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';

/// Termine la session et rouvre la boutique en visiteur.
///
/// Yobante Boutique se consulte librement, sans compte : après une déconnexion
/// on revient donc à l'accueil hors connexion. Renvoyer vers l'écran de
/// connexion enfermerait l'utilisateur sur une page dont il n'a rien à faire,
/// alors qu'il peut continuer à parcourir la boutique et remplir son panier.
Future<void> deconnecterEtRetournerBoutique(BuildContext context) async {
  context.read<AuthBloc>().add(LogoutRequested());

  // Le vidage du jeton est asynchrone : on l'attend avant de reconstruire
  // l'accueil, sinon celui-ci se réaffiche encore « connecté » (la barre de
  // navigation lit le jeton dans son initState).
  await sl<TokenService>().clearToken();

  // Navigateur racine plutôt que le contexte de la page : celle-ci est démontée
  // par la navigation qu'on déclenche.
  AuthInterceptor.navigatorKey.currentState?.pushNamedAndRemoveUntil(
    AppRouter.acheteurRoute,
    (_) => false,
  );
}
