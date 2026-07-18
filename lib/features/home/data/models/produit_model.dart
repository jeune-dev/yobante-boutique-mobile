/// Image supplémentaire d'un produit (galerie multi-images vendeur).
class ProduitImage {
  final String id;
  final String url;
  final int ordre;

  ProduitImage({required this.id, required this.url, this.ordre = 0});

  factory ProduitImage.fromJson(Map<String, dynamic> json) => ProduitImage(
        id: json['id']?.toString() ?? '',
        url: (json['url'] ?? json['image'] ?? '').toString(),
        ordre: (json['ordre'] is int)
            ? json['ordre'] as int
            : int.tryParse(json['ordre']?.toString() ?? '') ?? 0,
      );
}

class ProduitModel {
  final String id;
  final String nom;
  final String description;
  final String prix;
  final int quantite;
  final String image;
  final String ville;       // extrait de vendeur.boutiques[0].localisation
  final String categorie;   // extrait de categorie.nom
  final String vendeurNom;  // extrait de vendeur.nom + prenom
  final String vendeurNumero;  // extrait de vendeur.nom + prenom
  final String vendeurId;   // id du vendeur (pour le panier / commande)
  final String boutiqueId;  // id de la boutique (favoris / avis / signalements)
  final String boutiqueNom; // nom de la boutique (affiché côté client)
  final bool   disponible;  // produit disponible à la commande (côté vendeur)
  final List<ProduitImage>? images; // galerie d'images supplémentaires (vendeur)
  final int    stock;            // stock disponible (côté vendeur)
  final int    stockAlloue;      // stock réservé aux commandes en cours
  final String statutValidation; // en_attente | valide_step1 | valide | rejete
  final String messageVendeur;   // mot du vendeur au relecteur de la demande
  final String motifRejet;       // raison du refus, restituée dans le suivi

  ProduitModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.quantite,
    required this.image,
    required this.ville,
    required this.categorie,
    required this.vendeurNom,
    required this.vendeurNumero,
    required this.vendeurId,
    this.boutiqueId = '',
    this.boutiqueNom = '',
    this.disponible = true,
    this.images,
    this.stock = 0,
    this.stockAlloue = 0,
    this.statutValidation = 'valide',
    this.messageVendeur = '',
    this.motifRejet = '',
  });

  factory ProduitModel.fromJson(Map<String, dynamic> json) {
    // ── Vendeur ──────────────────────────────────────────────────────
    final vendeur   = json['vendeur'] as Map<String, dynamic>?;
    final vPrenom   = vendeur?['prenom'] ?? '';
    final vNom      = vendeur?['nom'] ?? '';
    final vendeurNom = '$vPrenom $vNom'.trim();
    final vendeurNumero = vendeur?['telephone'] ?? '';
    final vendeurId = (json['vendeurId'] ?? vendeur?['id'] ?? '').toString();

    // ── Localisation + id (première boutique du vendeur) ─────────────
    String ville = '';
    String boutiqueId = '';
    String boutiqueNom = '';
    if (vendeur != null) {
      final boutiques = vendeur['boutiques'];
      if (boutiques is List && boutiques.isNotEmpty) {
        ville = boutiques[0]['localisation'] ?? '';
        boutiqueId = boutiques[0]['id']?.toString() ?? '';
        boutiqueNom = boutiques[0]['nom'] ?? '';
      }
      // Backend Yobante : le vendeur porte un « profilVendeur » (sa boutique).
      final profil = vendeur['profilVendeur'];
      if (profil is Map) {
        if (ville.isEmpty)      ville = (profil['adresseBoutique'] ?? '').toString();
        if (boutiqueNom.isEmpty) boutiqueNom = (profil['nomBoutique'] ?? '').toString();
        if (boutiqueId.isEmpty)  boutiqueId = (profil['id'] ?? '').toString();
      }
    }
    // Fallback : à défaut d'id de boutique explicite, on retombe sur le
    // vendeur (cohérent avec le reste du modèle qui suppose 1 boutique/vendeur).
    if (boutiqueId.isEmpty) boutiqueId = vendeurId;

    // ── Catégorie ────────────────────────────────────────────────────
    final categorieMap = json['categorie'] as Map<String, dynamic>?;
    final categorie = categorieMap?['nom'] ?? '';

    // ── Images (galerie) — le backend renvoie soit des objets, soit des URLs ──
    List<ProduitImage>? images;
    final rawImages = json['images'];
    if (rawImages is List && rawImages.isNotEmpty) {
      images = <ProduitImage>[];
      for (var i = 0; i < rawImages.length; i++) {
        final e = rawImages[i];
        if (e is Map) {
          images.add(ProduitImage.fromJson(Map<String, dynamic>.from(e)));
        } else if (e is String && e.isNotEmpty) {
          images.add(ProduitImage(id: '$i', url: e, ordre: i));
        }
      }
    }
    // Image principale : champ « image » sinon 1re image de la galerie.
    String imagePrincipale = (json['image'] ?? '').toString();
    if (imagePrincipale.isEmpty && images != null && images.isNotEmpty) {
      imagePrincipale = images.first.url;
    }

    // ── Stock & statut de validation (côté vendeur) ───────────────────
    int parseInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    final int stock = json['stock'] != null
        ? parseInt(json['stock'])
        : parseInt(json['quantite']);
    final int stockAlloue = parseInt(json['stockAlloue']);
    final String statutValidation =
        (json['statutValidation'] ?? 'valide').toString();

    return ProduitModel(
      id:          json['id']?.toString() ?? '',
      nom:         json['nom'] ?? '',
      description: json['description'] ?? '',
      prix:        json['prix']?.toString() ?? '0',
      quantite:    parseInt(json['quantite']),
      image:       imagePrincipale,
      ville:       ville,
      categorie:   categorie,
      vendeurNom:  vendeurNom,
      vendeurNumero:  vendeurNumero,
      vendeurId:   vendeurId,
      boutiqueId:  boutiqueId,
      boutiqueNom: boutiqueNom,
      disponible:  json['disponible'] is bool ? json['disponible'] as bool : true,
      images:      images,
      stock:       stock,
      stockAlloue: stockAlloue,
      statutValidation: statutValidation,
      messageVendeur: json['messageVendeur']?.toString() ?? '',
      motifRejet: json['motifRejet']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'nom':         nom,
    'description': description,
    'prix':        prix,
    'quantite':    quantite,
    'image':       image,
    'ville':       ville,
    'categorie':   categorie,
    'vendeurNom':  vendeurNom,
  };
}