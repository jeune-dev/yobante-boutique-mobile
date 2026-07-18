import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer ce produit ?'),
        content: const Text('Le produit sera désactivé et ne sera plus visible des clients.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(SupprimerProduit(id));
            },
            child: const Text('Retirer', style: TextStyle(color: VendeurCouleurs.rouge)),
          ),
        ],
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
