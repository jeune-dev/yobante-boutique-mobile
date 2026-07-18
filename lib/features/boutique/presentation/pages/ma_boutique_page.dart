import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../injection_container.dart';
import '../bloc/boutique_bloc.dart';
import '../bloc/boutique_event.dart';
import '../bloc/boutique_state.dart';
import 'boutique_form_page.dart';
import '../../../vendeur/data/datasources/vendeur_produit_datasource.dart';
import '../../../home/data/models/produit_model.dart';
import '../../../home/presentation/pages/acheteur/produit_detail_page.dart';
import '../../../home/presentation/pages/acheteur/produit_page.dart';

class _C {
  static const green      = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const surface    = Color(0xFFF7F9FC);
  static const border     = Color(0xFFDDE3EF);
  static const sub        = Color(0xFF6B7280);
  static const label      = Color(0xFF9AA3B2);
}

/// « Ma boutique » — aperçu de la boutique du vendeur **tel que le client la voit**
/// (en-tête + produits), avec une icône d'édition en haut.
class MaBoutiquePage extends StatelessWidget {
  const MaBoutiquePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BoutiqueBloc>()..add(LoadMaBoutique()),
      child: const _MaBoutiqueView(),
    );
  }
}

class _MaBoutiqueView extends StatelessWidget {
  const _MaBoutiqueView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BoutiqueBloc, BoutiqueState>(
      listener: (context, state) {
        if (state is BoutiqueError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final boutique = state is BoutiqueLoaded ? state.boutique : null;
        return Scaffold(
          backgroundColor: _C.bg,
          appBar: AppBar(
            backgroundColor: _C.white,
            elevation: 0.5,
            foregroundColor: _C.black,
            title: const Text('Ma boutique'),
            actions: [
              if (boutique != null)
                IconButton(
                  tooltip: 'Modifier la boutique',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BoutiqueFormPage(boutique: boutique)),
                    );
                    if (context.mounted) {
                      context.read<BoutiqueBloc>().add(LoadMaBoutique());
                    }
                  },
                ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BoutiqueState state) {
    if (state is BoutiqueLoading || state is BoutiqueInitial) {
      return const Center(child: CircularProgressIndicator(color: _C.green));
    }
    if (state is BoutiqueInexistante) {
      return _buildAucuneBoutique(context);
    }
    if (state is BoutiqueLoaded) {
      final b = state.boutique;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildHeader(b),
          const SizedBox(height: 20),
          Text('Produits',
              style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: _C.black)),
          const SizedBox(height: 12),
          const _ProduitsBoutique(),
        ],
      );
    }
    return Center(
      child: TextButton(
        onPressed: () => context.read<BoutiqueBloc>().add(LoadMaBoutique()),
        child: const Text('Réessayer'),
      ),
    );
  }

  Widget _buildAucuneBoutique(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, color: _C.sub, size: 52),
            const SizedBox(height: 12),
            const Text("Vous n'avez pas encore de boutique",
                style: TextStyle(color: _C.sub)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BoutiqueFormPage()),
                );
                if (context.mounted) {
                  context.read<BoutiqueBloc>().add(LoadMaBoutique());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                foregroundColor: _C.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Créer ma boutique'),
            ),
          ],
        ),
      ),
    );
  }

  // ── En-tête boutique (vue client) ──────────────────────────────────────────
  Widget _buildHeader(b) {
    final hasLogo = (b.logo ?? '').isNotEmpty;
    final horaires = (b.heureOuverture != null && b.heureFermeture != null)
        ? '${b.heureOuverture} - ${b.heureFermeture}'
        : '';
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: hasLogo
                    ? CachedNetworkImage(
                        imageUrl: b.logo!, width: 64, height: 64, fit: BoxFit.cover)
                    : Container(
                        width: 64, height: 64,
                        color: _C.greenLight,
                        child: const Icon(Icons.storefront_rounded, color: _C.green, size: 28),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.nom,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w800, color: _C.black)),
                    if (b.localisation.toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: _C.green),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(b.localisation,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(fontSize: 12, color: _C.sub)),
                        ),
                      ]),
                    ],
                    if (horaires.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: _C.green),
                        const SizedBox(width: 3),
                        Text(horaires, style: GoogleFonts.dmSans(fontSize: 12, color: _C.green)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (b.description.toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(b.description,
                style: GoogleFonts.dmSans(fontSize: 13, color: _C.sub, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

// ── Produits de la boutique (produits du vendeur connecté) ────────────────────
class _ProduitsBoutique extends StatelessWidget {
  const _ProduitsBoutique();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProduitModel>>(
      future: sl<VendeurProduitDataSource>()
          .mesProduits()
          .catchError((_) => <ProduitModel>[]),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: _C.green)),
          );
        }
        final produits = snap.data ?? const <ProduitModel>[];
        if (produits.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Aucun produit dans votre boutique',
                  style: TextStyle(color: _C.sub)),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: produits.length,
          itemBuilder: (_, i) => ProduitGridCard(
            produit: produits[i],
            onTap: () => showProduitModal(context, produits[i], allowPanier: false),
            // Pas de bouton "+" : le vendeur ne dispose pas de panier.
          ),
        );
      },
    );
  }
}
