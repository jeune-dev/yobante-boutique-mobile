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
  static const greenLight = Color(0xFFEAEEF9);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const label = Color(0xFF9AA3B2);
  static const border = Color(0xFFDDE3EF);
}

/// Panier : tous les articles dans un même bloc, cochés à la demande.
///
/// Le client choisit ce qu'il commande maintenant plutôt que de tout envoyer :
/// le total suit la sélection, et ce qui n'est pas coché reste dans le panier
/// après la commande.
class PanierPage extends StatefulWidget {
  const PanierPage({super.key});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage> {
  final _panier = sl<PanierService>();

  /// Produits cochés. Tout est sélectionné à l'ouverture : commander la
  /// totalité reste le cas courant, décocher est l'exception.
  late Set<String> _selection = _panier.items.map((e) => e.produitId).toSet();

  @override
  void initState() {
    super.initState();
    _panier.addListener(_synchroniser);
  }

  @override
  void dispose() {
    _panier.removeListener(_synchroniser);
    super.dispose();
  }

  /// Écarte de la sélection les articles qui ont quitté le panier.
  void _synchroniser() {
    final presents = _panier.items.map((e) => e.produitId).toSet();
    final nettoyee = _selection.intersection(presents);
    if (nettoyee.length != _selection.length && mounted) {
      setState(() => _selection = nettoyee);
    }
  }

  bool get _toutSelectionne =>
      _panier.items.isNotEmpty && _selection.length == _panier.items.length;

  void _basculerTout(bool? valeur) {
    setState(() {
      _selection = valeur == true
          ? _panier.items.map((e) => e.produitId).toSet()
          : <String>{};
    });
  }

  void _basculer(String produitId, bool? valeur) {
    setState(() {
      if (valeur == true) {
        _selection.add(produitId);
      } else {
        _selection.remove(produitId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        centerTitle: true,
        title: Text(
          'Panier',
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _C.black,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _panier,
        builder: (context, _) {
          if (_panier.estVide) return const _PanierVide();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [_bloc()],
          );
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _panier,
        builder: (context, _) =>
            _panier.estVide ? const SizedBox.shrink() : _barreCommande(),
      ),
    );
  }

  // ── Bloc unique contenant tous les articles ────────────────────────────────
  Widget _bloc() {
    final items = _panier.items;
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          _enTete(items.length),
          const Divider(height: 1, color: _C.border),
          for (int i = 0; i < items.length; i++) ...[
            _ligne(items[i]),
            if (i < items.length - 1)
              const Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: _C.border,
              ),
          ],
        ],
      ),
    );
  }

  /// Case « Tout sélectionner » et décompte de la sélection.
  Widget _enTete(int total) {
    return InkWell(
      onTap: () => _basculerTout(!_toutSelectionne),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
        child: Row(
          children: [
            Checkbox(
              value: _toutSelectionne,
              // Sélection partielle : la case le montre plutôt que de paraître
              // simplement décochée.
              tristate: true,
              onChanged: _basculerTout,
              activeColor: _C.green,
              shape: const CircleBorder(),
            ),
            Expanded(
              child: Text(
                'Tout sélectionner',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: _C.black,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '${_selection.length}/$total',
              style: GoogleFonts.dmSans(color: _C.sub, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligne(PanierItem item) {
    final coche = _selection.contains(item.produitId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 12, 10),
      child: Row(
        children: [
          Checkbox(
            value: coche,
            onChanged: (v) => _basculer(item.produitId, v),
            activeColor: _C.green,
            shape: const CircleBorder(),
          ),
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
                Text(
                  item.nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: _C.black,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.sousTotal.toStringAsFixed(0)} FCFA',
                  style: GoogleFonts.sora(
                    color: _C.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _QtyStepper(
            quantite: item.quantite,
            onMoins: () =>
                _panier.changerQuantite(item.produitId, item.quantite - 1),
            onPlus: () =>
                _panier.changerQuantite(item.produitId, item.quantite + 1),
          ),
        ],
      ),
    );
  }

  // ── Récapitulatif ──────────────────────────────────────────────────────────
  /// Détail de la sélection, juste au-dessus du total.
  Widget _recapitulatif() {
    final articles = _panier.nombreArticlesSelection(_selection);
    return Column(
      children: [
        _ligneRecap('Articles sélectionnés', '$articles'),
        const SizedBox(height: 5),
        _ligneRecap(
          'Sous-total',
          '${_panier.totalSelection(_selection).toStringAsFixed(0)} FCFA',
        ),
        const SizedBox(height: 5),
        // Les frais dépendent de la ville de livraison : c'est le serveur qui
        // les calcule, à la validation.
        _ligneRecap('Livraison', 'calculée à la validation'),
      ],
    );
  }

  Widget _ligneRecap(String gauche, String droite) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(gauche, style: GoogleFonts.dmSans(color: _C.sub, fontSize: 13)),
      Text(
        droite,
        style: GoogleFonts.dmSans(
          color: _C.black,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    ],
  );

  // ── Barre de commande ──────────────────────────────────────────────────────
  Widget _barreCommande() {
    final total = _panier.totalSelection(_selection);
    final rien = _selection.isEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: _C.white,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: _recapitulatif(),
            ),
            const Divider(height: 1, color: _C.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.dmSans(
                            color: _C.sub,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${total.toStringAsFixed(0)} FCFA',
                          style: GoogleFonts.sora(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: _C.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: rien ? null : _commander,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.green,
                      foregroundColor: _C.white,
                      disabledBackgroundColor: _C.border,
                      disabledForegroundColor: _C.label,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      rien
                          ? 'Commander'
                          : 'Commander (${_panier.nombreArticlesSelection(_selection)})',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Validation de commande réservée aux clients connectés.
  ///
  /// Le client peut consulter la boutique et remplir son panier librement, mais
  /// doit se connecter avant de valider (le panier est conservé pendant ce temps).
  Future<void> _commander() async {
    if (_selection.isEmpty) return;
    final connecte = await sl<TokenService>().isAuthenticated;
    if (!mounted) return;

    if (!connecte) {
      _demanderConnexion(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutPage(produitIds: {..._selection}),
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _C.greenLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: _C.green,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
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
            Text(
              'Connectez-vous pour valider votre commande. Votre panier sera conservé.',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: _C.sub,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantite;
  final VoidCallback onMoins;
  final VoidCallback onPlus;
  const _QtyStepper({
    required this.quantite,
    required this.onMoins,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _circle(Icons.remove, onMoins),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Text(
            '$quantite',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _C.black,
            ),
          ),
        ),
        _circle(Icons.add, onPlus),
      ],
    );
  }

  Widget _circle(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _C.bg,
        shape: BoxShape.circle,
        border: Border.all(color: _C.border),
      ),
      child: Icon(icon, size: 15, color: _C.black),
    ),
  );
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
          Text(
            'Votre panier est vide',
            style: TextStyle(color: _C.sub, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();
  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    color: _C.bg,
    child: const Icon(Icons.image_not_supported_outlined, color: _C.sub),
  );
}
