import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/token_service.dart';
import '../../data/services/panier_service.dart';
import '../../data/models/panier_item.dart';
import 'checkout_page.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
}

class PanierPage extends StatelessWidget {
  const PanierPage({super.key});

  @override
  Widget build(BuildContext context) {
    final panier = sl<PanierService>();

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        centerTitle: true,
        title: Text('Panier',
            style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w800, color: _C.black)),
      ),
      body: ListenableBuilder(
        listenable: panier,
        builder: (context, _) {
          if (panier.estVide) {
            return const _PanierVide();
          }
          final groupes = panier.parVendeur;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              for (final entry in groupes.entries)
                _BoutiqueGroupe(
                  nomBoutique: entry.value.first.vendeurNom.isNotEmpty
                      ? entry.value.first.vendeurNom
                      : 'Boutique',
                  items: entry.value,
                  total: panier.totalVendeur(entry.key),
                  onMoins: (item) => panier.changerQuantite(
                      item.produitId, item.quantite - 1),
                  onPlus: (item) => panier.changerQuantite(
                      item.produitId, item.quantite + 1),
                  onCommander: () => _commander(context, entry.key),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Validation de commande réservée aux clients connectés.
  /// Le client peut consulter la boutique et remplir son panier librement, mais
  /// doit se connecter avant de valider (le panier est conservé pendant ce temps).
  Future<void> _commander(BuildContext context, String vendeurId) async {
    final connecte = await sl<TokenService>().isAuthenticated;
    if (!context.mounted) return;

    if (!connecte) {
      _demanderConnexion(context);
      return;
    }

    final panier = sl<PanierService>();
    final items = panier.parVendeur[vendeurId] ?? [];
    final total = panier.totalVendeur(vendeurId);

    if (!context.mounted) return;
    _afficherRecapCommande(context, vendeurId, items, total);
  }

  void _afficherRecapCommande(
    BuildContext context,
    String vendeurId,
    List<PanierItem> items,
    double total,
  ) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre
            Text(
              'Confirmation de commande',
              style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _C.black,
              ),
            ),
            const SizedBox(height: 24),

            // Liste des produits
            Container(
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.nom} x${item.quantite}',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _C.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 16, color: _C.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (${items.fold(0, (sum, item) => sum + item.quantite)} articles)',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: _C.sub,
                        ),
                      ),
                      Text(
                        '${total.toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _C.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.green,
                      side: const BorderSide(color: _C.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CheckoutPage(vendeurId: vendeurId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.green,
                      foregroundColor: _C.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Commander',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _demanderConnexion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône décorative
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: _C.green,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            Text(
              'Connexion requise',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _C.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Connectez-vous pour valider votre commande. Votre panier sera conservé.',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: _C.sub,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Boutons
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamed(AppRouter.loginRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.green,
                    foregroundColor: _C.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Se connecter',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Plus tard',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _C.sub,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantite;
  final VoidCallback onMoins;
  final VoidCallback onPlus;
  const _QtyStepper(
      {required this.quantite, required this.onMoins, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _circle(Icons.remove, onMoins),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('$quantite',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _C.black)),
        ),
        _circle(Icons.add, onPlus),
      ],
    );
  }

  Widget _circle(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _C.bg,
            shape: BoxShape.circle,
            border: Border.all(color: _C.border),
          ),
          child: Icon(icon, size: 16, color: _C.black),
        ),
      );
}

/// Groupe d'articles d'une même boutique, avec sous-total et bouton
/// « Commander » qui déclenche une commande **pour cette boutique uniquement**.
class _BoutiqueGroupe extends StatelessWidget {
  final String nomBoutique;
  final List<PanierItem> items;
  final double total;
  final void Function(PanierItem) onMoins;
  final void Function(PanierItem) onPlus;
  final VoidCallback onCommander;

  const _BoutiqueGroupe({
    required this.nomBoutique,
    required this.items,
    required this.total,
    required this.onMoins,
    required this.onPlus,
    required this.onCommander,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête boutique
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      size: 18, color: _C.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(nomBoutique,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: _C.black)),
                ),
                Text('${items.length} article${items.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: _C.sub, fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1, color: _C.border),
          // Articles de la boutique
          ...items.map((item) => Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item.image.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.image,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const _ImgFallback(),
                            )
                          : const _ImgFallback(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.nom,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: _C.black)),
                          const SizedBox(height: 4),
                          Text('${item.prix.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                  color: _C.green, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    _QtyStepper(
                      quantite: item.quantite,
                      onMoins: () => onMoins(item),
                      onPlus: () => onPlus(item),
                    ),
                  ],
                ),
              )),
          const Divider(height: 1, color: _C.border),
          // Sous-total + commander (par boutique)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sous-total',
                          style: TextStyle(color: _C.sub, fontSize: 12)),
                      Text('${total.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _C.black)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onCommander,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.green,
                    foregroundColor: _C.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Commander',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanierVide extends StatelessWidget {
  const _PanierVide();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.shopping_cart_outlined, size: 64, color: _C.sub),
          SizedBox(height: 12),
          Text('Votre panier est vide',
              style: TextStyle(color: _C.sub, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();
  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 64,
        color: _C.bg,
        child: const Icon(Icons.image_not_supported_outlined, color: _C.sub),
      );
}
