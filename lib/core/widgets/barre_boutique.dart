import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/commande/data/services/panier_service.dart';
import '../../features/commande/presentation/pages/panier_page.dart';
import '../../features/favoris/presentation/pages/favoris_page.dart';
import '../../features/home/presentation/pages/acheteur/main_client_page.dart';
import '../../features/home/presentation/pages/acheteur/profil_page.dart';
import '../../injection_container.dart';

class _C {
  static const green      = Color(0xFF163A9E);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const champ      = Color(0xFFF0F2F7);
  static const label      = Color(0xFF9AA3B2);
  static const or         = Color(0xFFF5C518);
}

/// Barre supérieure des pages ouvertes par-dessus la boutique (sections
/// promotionnelles, sous-sections…).
///
/// Ces pages s'affichent en plein écran : la barre de navigation du bas n'y est
/// plus visible, et toute la navigation passe donc par ici — retour, recherche,
/// panier, et le menu qui ramène aux grandes destinations de l'application.
class BarreBoutique extends StatelessWidget implements PreferredSizeWidget {
  /// Champ de recherche : filtre la liste de la page qui l'affiche.
  ///
  /// Nul sur une page qui n'a rien à filtrer — une fiche produit par exemple :
  /// [titre] prend alors sa place.
  final TextEditingController? controleurRecherche;
  final ValueChanged<String>? onRecherche;
  final String indication;

  /// Affiché à la place du champ de recherche quand celui-ci est absent.
  final String? titre;

  /// Raccourcis d'achat : panier et menu vers les destinations client.
  ///
  /// Retirés sur les écrans vendeur — il ne commande pas dans sa propre
  /// boutique, un panier ou un accès « Favoris » n'y aurait aucun sens.
  final bool actionsClient;

  const BarreBoutique({
    super.key,
    this.controleurRecherche,
    this.onRecherche,
    this.indication = 'Rechercher un produit',
    this.titre,
    this.actionsClient = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _C.white,
      elevation: 0.5,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _C.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: controleurRecherche == null
                    ? Text(
                        titre ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _C.black,
                        ),
                      )
                    : _champRecherche(context),
              ),
              if (actionsClient) ...[
                _panier(context),
                _menu(context),
              ],
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _champRecherche(BuildContext context) {
    final controleur = controleurRecherche!;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: _C.champ,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, size: 20, color: _C.label),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controleur,
              onChanged: onRecherche,
              textInputAction: TextInputAction.search,
              cursorColor: _C.green,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: _C.black, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: indication,
                hintStyle: GoogleFonts.dmSans(fontSize: 14, color: _C.label),
                border: InputBorder.none,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controleur,
            builder: (_, valeur, __) => valeur.text.isEmpty
                ? const SizedBox(width: 14)
                : GestureDetector(
                    onTap: () {
                      controleur.clear();
                      onRecherche?.call('');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: _C.label),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _panier(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PanierPage()),
      ),
      icon: ListenableBuilder(
        listenable: sl<PanierService>(),
        builder: (_, __) {
          final nombre = sl<PanierService>().nombreArticles;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_outlined, color: _C.black),
              if (nombre > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints:
                        const BoxConstraints(minWidth: 17, minHeight: 17),
                    decoration: const BoxDecoration(
                        color: _C.green, shape: BoxShape.circle),
                    child: Text(
                      '$nombre',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _C.or,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _menu(BuildContext context) {
    return PopupMenuButton<_Destination>(
      icon: const Icon(Icons.more_horiz_rounded, color: _C.black),
      color: _C.white,
      position: PopupMenuPosition.under,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (destination) => _aller(context, destination),
      itemBuilder: (_) => [
        _entree(_Destination.accueil, Icons.home_outlined, 'Accueil'),
        _entree(_Destination.categories, Icons.list_alt_rounded, 'Catégories'),
        _entree(_Destination.panier, Icons.shopping_cart_outlined, 'Panier'),
        _entree(_Destination.favoris, Icons.favorite_border_rounded, 'Favoris'),
        _entree(_Destination.compte, Icons.person_outline_rounded, 'Compte'),
      ],
    );
  }

  PopupMenuItem<_Destination> _entree(
      _Destination destination, IconData icone, String libelle) {
    return PopupMenuItem<_Destination>(
      value: destination,
      height: 46,
      child: Row(
        children: [
          Icon(icone, size: 21, color: _C.black),
          const SizedBox(width: 14),
          Text(
            libelle,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _C.black,
            ),
          ),
        ],
      ),
    );
  }

  void _aller(BuildContext context, _Destination destination) {
    switch (destination) {
      // Accueil et Catégories sont des onglets de la boutique : on referme les
      // pages empilées puis on demande l'onglet voulu à la page racine.
      case _Destination.accueil:
        Navigator.of(context).popUntil((route) => route.isFirst);
        ongletClientDemande.value = OngletClient.accueil;
      case _Destination.categories:
        Navigator.of(context).popUntil((route) => route.isFirst);
        ongletClientDemande.value = OngletClient.recherche;
      case _Destination.panier:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PanierPage()),
        );
      case _Destination.favoris:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FavorisPage()),
        );
      case _Destination.compte:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfilPage()),
        );
    }
  }
}

enum _Destination { accueil, categories, panier, favoris, compte }
