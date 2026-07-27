import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../injection_container.dart';
import '../../../home/data/models/produit_model.dart';
import '../bloc/vendeur_produit_bloc.dart';
import '../widgets/statut_chip.dart';
import 'produit_form_page.dart';

/// Catalogue du vendeur, séparé en deux onglets : ce qui est en ligne, et ce
/// qui attend encore une décision de l'administration.
class MesProduitsPage extends StatelessWidget {
  const MesProduitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: VendeurCouleurs.fond,
        appBar: AppBar(
          backgroundColor: VendeurCouleurs.blanc,
          elevation: 0.5,
          foregroundColor: VendeurCouleurs.noir,
          title: const Text('Mes produits'),
          bottom: const TabBar(
            labelColor: VendeurCouleurs.bleu,
            unselectedLabelColor: VendeurCouleurs.gris,
            indicatorColor: VendeurCouleurs.bleu,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            tabs: [
              Tab(text: 'Publiés'),
              Tab(text: 'En attente'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ListeProduits(statut: 'valide', messageVide: 'Aucun produit publié pour le moment'),
            _ListeProduits(
              statut: 'en_attente',
              messageVide: 'Aucune demande en attente de validation',
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste filtrée sur un statut de validation. Chaque onglet possède son propre
/// bloc pour que le changement d'onglet ne recharge pas l'autre liste.
class _ListeProduits extends StatelessWidget {
  final String statut;
  final String messageVide;

  const _ListeProduits({required this.statut, required this.messageVide});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VendeurProduitBloc>()..add(LoadMesProduits(statut: statut)),
      child: _ListeProduitsVue(statut: statut, messageVide: messageVide),
    );
  }
}

class _ListeProduitsVue extends StatelessWidget {
  final String statut;
  final String messageVide;

  const _ListeProduitsVue({required this.statut, required this.messageVide});

  Future<void> _ouvrirForm(BuildContext context, {ProduitModel? produit}) async {
    final bloc = context.read<VendeurProduitBloc>();
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProduitFormPage(produit: produit)),
    );
    if (res == true) bloc.add(LoadMesProduits(statut: statut));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VendeurProduitBloc, VendeurProduitState>(
      listener: (context, state) {
        if (state is VendeurProduitError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is VendeurProduitLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is VendeurProduitError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: VendeurCouleurs.gris),
                  ),
                ),
                TextButton(
                  onPressed: () => context
                      .read<VendeurProduitBloc>()
                      .add(LoadMesProduits(statut: statut)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        if (state is VendeurProduitLoaded) {
          if (state.produits.isEmpty) {
            return Center(
              child: Text(messageVide, style: const TextStyle(color: VendeurCouleurs.gris)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<VendeurProduitBloc>().add(LoadMesProduits(statut: statut)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: state.produits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _CarteProduit(
                produit: state.produits[i],
                onModifier: () => _ouvrirForm(context, produit: state.produits[i]),
                onSupprimer: () => _confirmerSuppression(
                  context,
                  context.read<VendeurProduitBloc>(),
                  state.produits[i].id,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _confirmerSuppression(BuildContext context, VendeurProduitBloc bloc, String id) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
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
                color: const Color(0xFFFFE5E5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: VendeurCouleurs.rouge,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Retirer ce produit ?',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Le produit sera désactivé et ne sera plus visible des clients.',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    bloc.add(SupprimerProduit(id));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VendeurCouleurs.rouge,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Retirer le produit',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
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

class _CarteProduit extends StatelessWidget {
  final ProduitModel produit;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _CarteProduit({
    required this.produit,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VendeurCouleurs.blanc,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VendeurCouleurs.bordure),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: produit.image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: produit.image,
                    width: 62,
                    height: 62,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _imageParDefaut(),
                  )
                : _imageParDefaut(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: VendeurCouleurs.noir,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${produit.prix} FCFA',
                  style: const TextStyle(
                    color: VendeurCouleurs.bleu,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatutChip(statut: produit.statutValidation, compact: true),
                    const SizedBox(width: 6),
                    Text(
                      'Stock ${produit.stock}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: produit.stock == 0
                            ? VendeurCouleurs.rouge
                            : VendeurCouleurs.gris,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'edit' ? onModifier() : onSupprimer(),
            // Pas de bascule de disponibilité : le backend ne l'expose pas.
            // Le retrait passe par « Retirer », qui désactive le produit.
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(value: 'delete', child: Text('Retirer')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imageParDefaut() => Container(
        width: 62,
        height: 62,
        color: VendeurCouleurs.fond,
        child: const Icon(Icons.image_not_supported_outlined, color: VendeurCouleurs.gris),
      );
}
