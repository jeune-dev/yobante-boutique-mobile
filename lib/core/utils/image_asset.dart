/// Décodage des images livrées avec l'application à la taille réellement
/// affichée.
///
/// `Image.asset(chemin, height: 76)` ne contraint que le dessin : Flutter
/// décode d'abord le PNG à sa taille d'origine. Le pictogramme fait 3000×3000,
/// soit 34 Mo de bitmap en mémoire pour occuper 76 points à l'écran ; les
/// bannières font 1672×941, soit 6 Mo chacune. L'accueil en affiche sept, on
/// dépasse donc les 70 Mo alors que le cache d'images de Flutter est limité à
/// 100 Mo : décodages à répétition, pression sur le ramasse-miettes, textures
/// géantes envoyées au GPU — le téléphone rame dès le lancement.
///
/// `cacheWidth` / `cacheHeight` demandent au codec de sous-échantillonner
/// pendant le décodage. La taille est exprimée en pixels physiques, d'où la
/// multiplication par la densité de l'écran.
///
/// Pendant du `imageOptimisee` des images distantes, côté assets locaux.
library;

import 'package:flutter/material.dart';

/// Affiche l'asset [chemin] en le décodant à la taille d'affichage.
///
/// [largeur] et [hauteur] sont la taille d'affichage en points, telles qu'on
/// les passerait à `Image.asset`. Une seule des deux suffit : le ratio de
/// l'image est conservé. `double.infinity` (« toute la largeur disponible »)
/// est accepté : on se cale alors sur la largeur de l'écran.
Image imageAsset(
  BuildContext context,
  String chemin, {
  double? largeur,
  double? hauteur,
  BoxFit? fit,
}) {
  final densite = MediaQuery.of(context).devicePixelRatio;
  final int? cacheLargeur;
  final int? cacheHauteur;

  if (largeur != null && largeur.isFinite) {
    cacheLargeur = (largeur * densite).round();
    cacheHauteur = null;
  } else if (hauteur != null && hauteur.isFinite) {
    cacheLargeur = null;
    cacheHauteur = (hauteur * densite).round();
  } else {
    // Largeur non contrainte : l'image ne dépassera jamais l'écran.
    cacheLargeur = (MediaQuery.of(context).size.width * densite).round();
    cacheHauteur = null;
  }

  return Image.asset(
    chemin,
    width: largeur,
    height: hauteur,
    fit: fit,
    cacheWidth: cacheLargeur,
    cacheHeight: cacheHauteur,
  );
}
