import 'package:flutter/material.dart';
import 'package:yobante/features/auth/presentation/pages/login_page.dart';
import 'package:yobante/features/auth/presentation/pages/register_page.dart';
import 'package:yobante/features/auth/presentation/pages/onboarding_page.dart';
import 'package:yobante/features/home/presentation/pages/home.dart';
import 'package:yobante/features/home/presentation/pages/acheteur/main_client_page.dart';
import 'package:yobante/features/home/presentation/pages/vendeur/main_vendeur_page.dart';
import 'package:yobante/features/auth/domain/entities/user.dart';
import 'package:yobante/features/commande/presentation/pages/panier_page.dart';
import 'package:yobante/features/commande/presentation/pages/checkout_page.dart';
import 'package:yobante/features/commande/presentation/pages/mes_commandes_page.dart';
import 'package:yobante/features/commande/presentation/pages/commande_detail_page.dart';
import 'package:yobante/features/compte/presentation/pages/forgot_password_page.dart';

class AppRouter {
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String acheteurRoute = '/acheteur';
  static const String vendeurRoute = '/vendeur';
  static const String panierRoute = '/panier';
  static const String checkoutRoute = '/checkout';
  static const String mesCommandesRoute = '/mes-commandes';
  static const String commandeDetailRoute = '/commande-detail';
  static const String forgotPasswordRoute = '/forgot-password';

  /// Écran d'accueil correspondant à un rôle.
  ///
  /// Point unique de décision : le rôle détermine l'interface, et les trois
  /// états (visiteur, client connecté, vendeur) doivent rester distincts.
  /// Les administrateurs gèrent la boutique depuis le dashboard web : sur
  /// mobile, ils voient l'interface client.
  static String routeSelonRole(String? role) =>
      role?.toUpperCase() == 'VENDEUR' ? vendeurRoute : acheteurRoute;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());

      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginPage());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case acheteurRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => MainAcheteurPage(user: user),
        );

      case vendeurRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => MainVendeurPage(user: user),
        );

      case panierRoute:
        return MaterialPageRoute(builder: (_) => const PanierPage());

      case checkoutRoute:
        return MaterialPageRoute(builder: (_) => const CheckoutPage());

      case mesCommandesRoute:
        return MaterialPageRoute(builder: (_) => const MesCommandesPage());

      case commandeDetailRoute:
        return MaterialPageRoute(
          builder: (_) => const CommandeDetailPage(),
          settings: settings,
        );

      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

      default:
        // Yobante Boutique = application 100% client : par défaut on ouvre
        // directement la boutique (consultation libre, sans compte).
        return MaterialPageRoute(
          builder: (_) => const MainAcheteurPage(),
        );
    }
  }
}
