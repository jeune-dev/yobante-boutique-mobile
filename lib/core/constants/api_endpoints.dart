// Constantes des endpoints REST du backend Yobante Boutique.
//
// Regroupées par domaine fonctionnel afin d'éviter les chaînes littérales
// éparpillées dans les datasources. Le préfixe commun de l'API est déjà
// configuré comme `baseUrl` du Dio partagé (voir injection_container.dart,
// variable `API_BASE_URL` du .env) : il ne doit donc PAS être répété ici.

/// Authentification (déjà utilisée par [AuthRemoteDataSource]).
class AuthEndpoints {
  AuthEndpoints._();

  static const login = '/auth/login';
  static const register = '/auth/register';
}

/// Produits/boutiques côté acheteur (feature `home`).
class ProduitEndpoints {
  ProduitEndpoints._();

  static const listeProduits = '/produits';
  static const listeBoutiques = '/boutiques';
  static const rechercherProduitCategorie =
      '/acheteurs/rechercher-produit-categorie';
  static const filtrerProduitVille = '/acheteurs/filtrer-produit-ville';
  static String listeProduitParBoutique(String boutiqueId) =>
      '/acheteurs/liste-produit-par-boutique/$boutiqueId';
  static String contacterVendeurParWhatsapp(String produitId) =>
      '/acheteurs/contacter-vendeur-par-whatsapp/$produitId';
  static String produit(String id) => '/acheteurs/produit/$id';

  // ── Découverte / accueil (endpoints backend jusque-là inexploités) ──────────
  static const accueil = '/acheteurs/accueil';
  static const monTableauDeBord = '/acheteurs/mon-tableau-de-bord';
  static const produitsTendance = '/produits/featured';
  static const nouvellesBoutiques = '/boutiques';
  static const boutiquesVerifiees = '/boutiques';
  static const rechercheGlobale = '/produits/recherche';
  static const produitsAvecFiltres = '/acheteurs/produits';
  static const boutiquesProches = '/acheteurs/boutiques-proches';
  static String boutiqueDetail(String id) => '/acheteurs/boutique/$id';
  static String vueProduit(String id) => '/acheteurs/produit/$id/vue';
}

/// Alias des endpoints acheteur générique (utilisé par plusieurs features).
class AcheteurEndpoints {
  AcheteurEndpoints._();

  static const mesAvis = '/acheteurs/mes-avis';
  static String avis(String id) => '/acheteurs/avis/$id';
}

/// Commandes / panier (feature `commande`).
class CommandeEndpoints {
  CommandeEndpoints._();

  static const commandes = '/commandes';
  static String commande(String id) => '/commandes/$id';
  static String annuler(String id) => '/commandes/$id/annuler';
  static String payer(String id) => '/commandes/$id/payer';
  static String paiement(String id) => '/commandes/$id/paiement';
}

/// Gestion des produits côté vendeur (feature `vendeur`).
class VendeurProduitEndpoints {
  VendeurProduitEndpoints._();

  static const listeProduits = '/vendeur/produits';
  static const categories = '/categories';
  static const ajouterProduit = '/vendeur/produits';
  static String produit(String id) => '/vendeur/produits/$id';
  static String modifierProduit(String id) => '/vendeur/produits/$id';
  static String supprimerProduit(String id) => '/vendeur/produits/$id';
  static String stock(String id) => '/vendeur/produits/$id/stock';
}

/// Compte utilisateur (profil connecté, mot de passe).
class CompteEndpoints {
  CompteEndpoints._();

  static const me = '/profile';
  static const modifierProfil = '/profile';
  static const adresses = '/profile/adresses';
  static String adresse(String id) => '/profile/adresses/$id';
  static String adresseParDefaut(String id) => '/profile/adresses/$id/default';
  static const changePassword = '/auth/change-password';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  // Suppression de compte en libre-service (exigence Google Play : toute app
  // avec création de compte doit permettre à l'utilisateur de le supprimer).
  // ⚠️ Pas encore d'endpoint côté backend (à créer).
  static const deleteAccount = '/profile';
}


/// Abonnement vendeur.
class AbonnementEndpoints {
  AbonnementEndpoints._();

  static const monAbonnement = '/vendeur/mon-abonnement';
  static const initierRenouvellement = '/vendeur/initier-renouvellement';
  static const historiquePaiements = '/vendeur/historique-paiements';
}

/// Paiement (Orange Money / Wave).
class PaiementEndpoints {
  PaiementEndpoints._();

  static const payer = '/paiement/payer';
  static const historique = '/paiement';
  static String paiement(String id) => '/paiement/$id';
}

/// Favoris (acheteur).
class FavorisEndpoints {
  FavorisEndpoints._();

  static const favoris = '/favoris';
  static String parId(String boutiqueId) => '/favoris/$boutiqueId';
}

/// Avis (acheteur + vendeur).
class AvisEndpoints {
  AvisEndpoints._();

  static const avis = '/avis';
  static String parBoutique(String boutiqueId) => '/avis/$boutiqueId';
  static String supprimer(String avisId) => '/avis/$avisId';
  static const mesAvis = '/acheteurs/mes-avis';
  static String modifier(String id) => '/acheteurs/avis/$id';
  static const mesAvisRecus = '/vendeur/mes-avis';
  static String repondre(String avisId) => '/vendeur/avis/$avisId/repondre';
}

/// Messagerie (temps réel via socket + REST).
class MessagerieEndpoints {
  MessagerieEndpoints._();

  static const messages = '/messages';
  static const conversations = '/messages/conversations';
  static const nonLus = '/messages/non-lus';
  static String historique(String userId) => '/messages/$userId';
  static String marquerLu(String messageId) => '/messages/$messageId/lire';
}

/// Notifications (temps réel via socket + REST) + device token FCM.
class NotificationsEndpoints {
  NotificationsEndpoints._();

  static const notifications = '/notifications';
  static const nonLues = '/notifications/non-lues';
  static const toutesLues = '/notifications/toutes-lues';
  static String marquerLue(String id) => '/notifications/$id/lire';
  static const registerDeviceToken = '/device-token/register';
  static const unregisterDeviceToken = '/device-token/unregister';
}

/// Bannières de la section principale de l'accueil.
class BanniereEndpoints {
  BanniereEndpoints._();

  static const actives = '/bannieres';
  static String get bannieres => '/bannieres';
}

/// Promotions.
class PromotionsEndpoints {
  PromotionsEndpoints._();

  static const actives = '/promotions/actives';
  static const promotions = '/promotions';
  static const blocs = '/promotions/blocs';
  /// Produits d'une sous-section précise, dans l'ordre fixé par l'administration.
  static String produitsDuBloc(String blocId) => '/promotions/blocs/$blocId/produits';
  /// Promotions d'une section : nos_promos_du_moment, a_ne_pas_rater…
  static String section(String section) => '/promotions/$section';
  static String parId(String id) => '/promotions/$id';
}

/// Rayons (catalogue acheteur).
class RayonEndpoints {
  RayonEndpoints._();

  static String get rayons => '/rayons';
  static String sousRayons(String rayonId) => '/rayons/$rayonId/sous-rayons';
  static String produitsDuRayon(String rayonId) => '/rayons/$rayonId/produits';
  static String produitsduSousRayon(String sousRayonId) =>
      '/rayons/sous-rayons/$sousRayonId/produits';
}

/// Promotions groupées (nos promos du moment / à ne pas rater / à venir).
class PromotionEndpoints {
  PromotionEndpoints._();

  static String get groupees => '/promotions/groupees';
}

/// Signalements.
class SignalementsEndpoints {
  SignalementsEndpoints._();

  static const signalements = '/signalements';
  static const mesSignalements = '/signalements/mes-signalements';
}

/// Commandes et ventes du vendeur.
class VendeurCommandeEndpoints {
  VendeurCommandeEndpoints._();

  static const commandes = '/vendeur/commandes';
  static const ventes = '/vendeur/commandes/ventes';
  static String commande(String id) => '/vendeur/commandes/$id';
}

/// Statistiques catalogue du vendeur (compteurs de produits par statut).
class VendeurDashboardEndpoints {
  VendeurDashboardEndpoints._();

  static const statsProduits = '/vendeur/produits/stats';
}
