/// Optimisation des images servies par Cloudinary.
///
/// Les visuels stockés font 1,5 à 1,9 Mo : les afficher tels quels dans un
/// carrousel de 302 px de large fait télécharger dix fois trop d'octets, ce qui
/// se paie cash en connexion mobile.
///
/// Cloudinary applique des transformations à la volée en les insérant dans
/// l'URL, juste après `/upload/`. On demande donc la largeur réellement
/// affichée, une qualité et un format choisis automatiquement selon le
/// terminal (`q_auto`, `f_auto` : WebP ou AVIF quand c'est possible).
library;

/// Marqueur à partir duquel Cloudinary lit les transformations.
const _marqueur = '/upload/';

/// Renvoie une variante allégée de [url], dimensionnée pour [largeur] points.
///
/// [densite] tient compte de la densité de l'écran : on demande un peu plus de
/// pixels que de points pour rester net sans exploser le poids.
///
/// Une URL qui ne vient pas de Cloudinary est renvoyée telle quelle : cette
/// fonction ne doit jamais casser un visuel hébergé ailleurs.
String imageOptimisee(String? url, {required int largeur, double densite = 2}) {
  if (url == null || url.isEmpty) return '';
  if (!url.contains('res.cloudinary.com') || !url.contains(_marqueur)) return url;

  // Déjà transformée : on ne superpose pas deux jeux de transformations.
  final apres = url.split(_marqueur).last;
  if (apres.startsWith('w_') || apres.startsWith('q_') || apres.startsWith('f_')) {
    return url;
  }

  final pixels = (largeur * densite).round();
  // `c_limit` ne fait que réduire : une image plus petite que demandée n'est
  // jamais agrandie, ce qui éviterait un flou inutile.
  final transformation = 'w_$pixels,c_limit,q_auto,f_auto';

  return url.replaceFirst(_marqueur, '$_marqueur$transformation/');
}
