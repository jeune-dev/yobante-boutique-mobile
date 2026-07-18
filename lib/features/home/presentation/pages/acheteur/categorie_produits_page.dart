import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yobante/core/connection/auth_interceptor.dart';

import '../../../../../injection_container.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/datasources/produit_remote_datasource.dart';
import '../../../../commande/data/services/panier_service.dart';
import '../../../../commande/data/models/panier_item.dart';
import '../../../../commande/presentation/pages/panier_page.dart';

class _C {
  static const green      = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const surface    = Color(0xFFF7F9FC);
  static const border     = Color(0xFFDDE3EF);
  static const label      = Color(0xFF9AA3B2);
  static const sub        = Color(0xFF6B7280);
}

/// Page produits d'un rayon / sous-rayon.
/// Les catégories n'ayant pas (encore) d'endpoint dédié côté backend, on
/// s'appuie sur la recherche globale en utilisant le nom du rayon comme mot-clé.
class CategorieProduitsPage extends StatefulWidget {
  final String titre;
  final IconData? icon;
  final String? sousTitre;

  const CategorieProduitsPage({
    super.key,
    required this.titre,
    this.icon,
    this.sousTitre,
  });

  @override
  State<CategorieProduitsPage> createState() => _CategorieProduitsPageState();
}

class _CategorieProduitsPageState extends State<CategorieProduitsPage> {
  final _ds = sl<ProduitRemoteDataSource>();
  final _panier = sl<PanierService>();

  List<ProduitModel> _produits = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _ds.rechercheGlobale(widget.titre);
      if (!mounted) return;
      setState(() { _produits = res.produits; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Chargement impossible'; _loading = false; });
    }
  }

  Future<void> _addCart(ProduitModel p) async {
    await _panier.ajouter(PanierItem(
      produitId: p.id,
      nom: p.nom,
      prix: double.tryParse(p.prix) ?? 0,
      image: p.image,
      vendeurId: p.vendeurId,
      vendeurNom: p.vendeurNom,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${p.nom} ajouté au panier'),
      backgroundColor: _C.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      action: SnackBarAction(
        label: 'Voir',
        textColor: Colors.white,
        onPressed: () => AuthInterceptor.navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const PanierPage()),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (widget.icon != null) ...[
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _C.greenLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: _C.green, size: 19),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.titre,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                          fontSize: 16, fontWeight: FontWeight.w800, color: _C.black)),
                  if (widget.sousTitre != null)
                    Text(widget.sousTitre!,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(fontSize: 11, color: _C.label)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PanierPage()),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5));
    }
    if (_error != null) {
      return _emptyState(Icons.error_outline_rounded, _error!, retry: true);
    }
    if (_produits.isEmpty) {
      return _emptyState(Icons.inventory_2_outlined,
          'Aucun produit dans « ${widget.titre} » pour le moment');
    }
    return RefreshIndicator(
      color: _C.green,
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
        ),
        itemCount: _produits.length,
        itemBuilder: (_, i) => _produitCard(_produits[i]),
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: _C.label),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 14, color: _C.sub)),
            if (retry) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(12)),
                  child: Text('Réessayer',
                      style: GoogleFonts.dmSans(color: _C.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _produitCard(ProduitModel p) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                image: p.image.isNotEmpty
                    ? DecorationImage(image: NetworkImage(p.image), fit: BoxFit.cover)
                    : null,
              ),
              child: p.image.isEmpty
                  ? const Center(child: Icon(Icons.image_outlined, color: _C.label))
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: _C.black)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: p.prix, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800, color: _C.black)),
                      TextSpan(text: ' F', style: GoogleFonts.dmSans(fontSize: 10, color: _C.label)),
                    ])),
                    GestureDetector(
                      onTap: () => _addCart(p),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.add_rounded, color: _C.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
