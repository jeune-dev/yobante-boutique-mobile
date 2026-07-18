import 'package:flutter/material.dart';

/// Catalogue des rayons Yobante Boutique et de leurs sous-rayons.
/// Utilisé par la page « Rechercher » (grille de rayons → sous-rayons).
class Rayon {
  final String nom;
  final IconData icon;
  final List<String> sousRayons;

  /// Rayon spécial « Promotions » : ouvre le récap des promos actives
  /// (avec compte à rebours) au lieu d'une liste de sous-rayons.
  final bool estPromotions;

  const Rayon(
    this.nom,
    this.icon,
    this.sousRayons, {
    this.estPromotions = false,
  });
}

const List<Rayon> kRayons = [
  Rayon('Promotions', Icons.local_offer_rounded, [], estPromotions: true),
  Rayon('Produits locaux', Icons.storefront_rounded, [
    'Boissons',
    'Gourmandises du pays',
  ]),
  Rayon('Cafés', Icons.coffee_rounded, [
    'Dosettes et capsules',
    'Cafés en grains',
    'Cafés moulus',
    'Cafés concentrés',
    'Cafés solubles',
    'Filtres et détartrant',
  ]),
  Rayon('Mode et textile de chez nous', Icons.checkroom_rounded, [
    'Chaussures',
    'Maroquinerie',
    'Habillement',
    'Bijoux',
  ]),
  Rayon('Traiteur', Icons.restaurant_rounded, [
    'Entrées',
    'Plats',
    'Desserts',
  ]),
  Rayon('Mobilier et décoration', Icons.weekend_rounded, [
    'Linge de maison',
    'Literie',
    'Cuisson et ustensiles de cuisine',
    'Vaisselle et art de la table',
    'Mobilier et décoration',
  ]),
  Rayon('Fruits et légumes', Icons.eco_rounded, [
    'Fruits',
    'Légumes',
    'Prêt à consommer',
    'Fruits et légumes secs',
    'Graines',
  ]),
  Rayon('Viande et poissons', Icons.set_meal_rounded, [
    'Boucherie',
    'Volaille et rôtisserie',
    'Poissonnerie',
    'Traiteur de la mer',
  ]),
  Rayon('Crèmerie et produits laitiers', Icons.egg_rounded, [
    'Yaourts',
    'Desserts et compotes',
    'Œufs',
  ]),
  Rayon('Charcuterie et traiteur', Icons.lunch_dining_rounded, [
    'Charcuterie',
    'Entrées et salades',
    'Pizza',
    'Plats cuisinés',
  ]),
  Rayon('Surgelés', Icons.ac_unit_rounded, [
    'Glaces',
    'Fruits et légumes',
    'Poisson',
    'Viande',
    'Pizza',
    'Glaçons',
  ]),
  Rayon('Bébé', Icons.child_care_rounded, [
    'Change et soins',
    'Bain et toilette',
    'Vêtements',
    'Promenade',
    'Chambre',
    'Éveil',
  ]),
  Rayon('Épicerie sucrée', Icons.cake_rounded, [
    'Cafés, petit déjeuner',
    'Thés, infusions et boissons chaudes',
    'Confiserie et chocolat',
    'Biscuits, gâteaux',
    'Compotes, fruits au sirop',
    'Crèmes dessert',
    'Sucre',
    'Farines et aide à la pâtisserie',
  ]),
  Rayon('Épicerie salée', Icons.soup_kitchen_rounded, [
    'Huiles, vinaigres et vinaigrettes',
    'Pâtes',
    'Sauces chaudes',
    'Sauces froides',
    'Conserves et bocaux',
    'Riz, purée et féculents',
    'Cornichons et condiments',
    'Sels, épices et bouillons',
    'Soupes',
  ]),
  Rayon('Boissons', Icons.local_drink_rounded, [
    'Colas, sirops et sodas',
    'Eaux',
    'Jus de fruits',
  ]),
  Rayon('Pains et pâtisserie', Icons.bakery_dining_rounded, [
    'Gâteaux à partager',
    'Pâtisseries individuelles',
    'Tartes',
    'Macarons et mignardises',
    'Beignets',
    'Muffins',
  ]),
  Rayon('Entretien et nettoyage', Icons.cleaning_services_rounded, [
    'Anti-moustiques et insecticides',
    'Lessives, adoucissants et soin du linge',
    'Produits nettoyants',
    'Essuie-tout',
    'Papier toilette et mouchoirs',
    'Désodorisants',
    'Accessoires de ménage',
  ]),
  Rayon('Hygiène et beauté', Icons.spa_rounded, [
    'Produits solaires',
    'Soins du visage',
    'Soins du corps',
    'Soins des cheveux',
    'Hygiène dentaire',
    'Hygiène intime',
    'Hommes',
    'Maquillage',
    'Enfants premiers soins',
    'Incontinence',
    'Cotons',
  ]),
  Rayon('Animalerie', Icons.pets_rounded, [
    'Chien',
    'Chat',
    'Basse-cour',
    'Poisson',
  ]),
  Rayon('Jeux vidéo', Icons.sports_esports_rounded, [
    'Consoles',
    'Jeux',
    'Accessoires',
  ]),
  Rayon('Smartphone et objets connectés', Icons.smartphone_rounded, [
    'Téléphones',
    'Montres et bracelets connectés',
    'Cartes mémoire',
    'Batteries externes',
    'Objets connectés',
  ]),
  Rayon('Informatique et bureau', Icons.computer_rounded, [
    'Ordinateurs portables',
    'Ordinateurs de bureau',
    'Écrans PC',
    'Tablettes et iPad',
    'Imprimantes et scanners',
    'Cartouches, toner et papier',
    'Casques, micros et enceintes',
    'Stockage',
    'Souris, clavier et tapis',
    'Accessoires informatique',
  ]),
  Rayon('Image et son', Icons.tv_rounded, [
    'Téléviseurs',
    'Barres de son',
    'Home cinéma',
    'Casques et écouteurs',
    'Enceintes Bluetooth et radio',
  ]),
  Rayon('Sport', Icons.sports_soccer_rounded, [
    'Chaussures',
    'Tenues de sport',
  ]),
  Rayon('Mode et textile', Icons.shopping_bag_rounded, [
    'Chaussures',
    'Habillement',
    'Montres',
    'Bijoux',
  ]),
];
