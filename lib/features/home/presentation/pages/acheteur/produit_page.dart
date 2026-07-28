import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yobante/features/auth/domain/entities/user.dart';
import '../../bloc/produit_bloc.dart';
import '../../bloc/produit_event.dart';
import '../../bloc/produit_state.dart';
import '../../../data/models/produit_model.dart';
import '../../../../../injection_container.dart';
import '../../../../../core/routes/app_router.dart';
import '../../../../commande/data/services/panier_service.dart';
import '../../widgets/produit_card.dart';

class _C {
  static const green      = Color(0xFF163A9E);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const label      = Color(0xFF9AA3B2);
  static const orange     = Color(0xFFFF5722);
}

// ══════════════════════════════════════════════════════════════════════════════
class ProduitPage extends StatefulWidget {
  final User? user;
  const ProduitPage({super.key, this.user});

  @override
  State<ProduitPage> createState() => _ProduitPageState();
}

class _ProduitPageState extends State<ProduitPage> {
  String           _search     = '';
  final _searchCtrl            = TextEditingController();
  ProduitBloc?             _produitBloc;

  @override
  void initState() {
    super.initState();
    _initBloc();
  }

  Future<void> _initBloc() async {
    try {
      // Récupérés via l'injection de dépendances (Dio partagé + API_BASE_URL du .env)
      final bloc = sl<ProduitBloc>();
      bloc.add(LoadProduits());
      if (mounted) setState(() => _produitBloc = bloc);
    } catch (e) {
      debugPrint('Erreur init bloc ProduitPage: $e');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _produitBloc?.close();
    super.dispose();
  }


  List<ProduitModel> _filter(List<ProduitModel> produits) {
    if (_search.isEmpty) return produits;
    return produits.where((p) =>
    p.nom.toLowerCase().contains(_search.toLowerCase()) ||
        p.ville.toLowerCase().contains(_search.toLowerCase()),
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _C.green,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRouter.panierRoute),
        child: ListenableBuilder(
          listenable: sl<PanierService>(),
          builder: (_, __) {
            final n = sl<PanierService>().nombreArticles;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                if (n > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text('$n',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: _C.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildResultCount(),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _C.black,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Décoration cercle
          Stack(
            children: [
              Positioned(
                right: -10, top: -10,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.green.withOpacity(0.07),
                  ),
                ),
              ),
              // Titre
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Les ',
                    style: GoogleFonts.sora(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: _C.white, letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Produits',
                    style: GoogleFonts.sora(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: _C.green, letterSpacing: -0.5,
                    ),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de recherche améliorée
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.dmSans(fontSize: 15, color: _C.white),
              cursorColor: _C.green,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.4),
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: _C.green, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _C.green, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: _C.green, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Compteur résultats ─────────────────────────────────────────────────────
  Widget _buildResultCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Produits',
            style: GoogleFonts.sora(
              fontSize: 14, fontWeight: FontWeight.w700, color: _C.black,
            ),
          ),
          GestureDetector(
            onTap: () => _produitBloc?.add(LoadProduits()),
            child: Row(
              children: [
                Text('Actualiser',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: _C.green,
                    )),
                const SizedBox(width: 3),
                const Icon(Icons.refresh_rounded, color: _C.green, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Grille produits ────────────────────────────────────────────────────────
  Widget _buildGrid() {
    if (_produitBloc == null) {
      return const Center(
        child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5),
      );
    }

    return BlocBuilder<ProduitBloc, ProduitState>(
      bloc: _produitBloc,
      builder: (context, state) {
        if (state is ProduitLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5),
          );
        }

        if (state is ProduitError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: _C.orange, size: 48),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Erreur: ${state.message}',
                    style: GoogleFonts.dmSans(color: _C.orange),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _produitBloc?.add(LoadProduits()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _C.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Réessayer',
                        style: GoogleFonts.dmSans(
                            color: _C.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is ProduitLoaded) {
          final list = _filter(state.produits);

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, color: _C.label, size: 48),
                  const SizedBox(height: 12),
                  Text('Aucun produit trouvé',
                      style: GoogleFonts.sora(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: _C.label,
                      )),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _produitBloc?.add(LoadProduits()),
            color: _C.green,
            backgroundColor: _C.white,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              physics: const BouncingScrollPhysics(),
              gridDelegate: grilleProduits,
              itemCount: list.length,
              itemBuilder: (_, i) => ProduitCard(produit: list[i]),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

}
