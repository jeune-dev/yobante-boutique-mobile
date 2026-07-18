import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../injection_container.dart';
import '../../../home/data/models/produit_model.dart';
import '../bloc/vendeur_produit_bloc.dart';
import '../widgets/statut_chip.dart';
import 'produit_form_page.dart';

/// Demandes de publication : dépôt d'une nouvelle demande et suivi de celles
/// déjà envoyées.
///
/// Une demande n'est pas une entité distincte côté backend : soumettre un
/// produit le crée avec `statutValidation = en_attente`. Le suivi consiste
/// donc à lister ses produits non encore publiés.
class DemandePublicationPage extends StatelessWidget {
  const DemandePublicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VendeurProduitBloc>()..add(LoadMesProduits()),
      child: const _DemandeVue(),
    );
  }
}

class _DemandeVue extends StatelessWidget {
  const _DemandeVue();

  Future<void> _nouvelleDemande(BuildContext context) async {
    final bloc = context.read<VendeurProduitBloc>();
    final envoye = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProduitFormPage()),
    );
    if (envoye != true) return;
    bloc.add(LoadMesProduits());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande envoyée — elle est maintenant en attente de validation'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendeurCouleurs.fond,
      appBar: AppBar(
        backgroundColor: VendeurCouleurs.blanc,
        elevation: 0.5,
        foregroundColor: VendeurCouleurs.noir,
        title: const Text('Demandes de publication'),
      ),
      body: BlocBuilder<VendeurProduitBloc, VendeurProduitState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              _carteAppel(context),
              const SizedBox(height: 24),
              const Text(
                'Suivi de mes demandes',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: VendeurCouleurs.noir,
                ),
              ),
              const SizedBox(height: 12),
              ..._suivi(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _carteAppel(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [VendeurCouleurs.bleu, Color(0xFF2A55C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proposer un nouveau produit',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Préparez la fiche produit — photos, prix, description et stock '
              'souhaité. L\'administration la validera avant publication.',
              style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _nouvelleDemande(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VendeurCouleurs.or,
                  foregroundColor: VendeurCouleurs.noir,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Créer une demande',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      );

  List<Widget> _suivi(BuildContext context, VendeurProduitState state) {
    if (state is VendeurProduitLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (state is VendeurProduitError) {
      return [
        Center(
          child: Column(
            children: [
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: VendeurCouleurs.gris),
              ),
              TextButton(
                onPressed: () =>
                    context.read<VendeurProduitBloc>().add(LoadMesProduits()),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ];
    }
    if (state is VendeurProduitLoaded) {
      // Une demande n'a plus lieu d'être suivie une fois le produit publié.
      final demandes = state.produits
          .where((p) => p.statutValidation != 'valide')
          .toList();

      if (demandes.isEmpty) {
        return [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: VendeurCouleurs.blanc,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VendeurCouleurs.bordure),
            ),
            child: const Column(
              children: [
                Icon(Icons.inbox_rounded, color: VendeurCouleurs.gris, size: 30),
                SizedBox(height: 8),
                Text(
                  'Aucune demande en cours',
                  style: TextStyle(color: VendeurCouleurs.gris, fontSize: 13),
                ),
              ],
            ),
          ),
        ];
      }

      return [
        for (final demande in demandes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CarteDemande(produit: demande),
          ),
      ];
    }
    return const [SizedBox.shrink()];
  }
}

class _CarteDemande extends StatelessWidget {
  final ProduitModel produit;
  const _CarteDemande({required this.produit});

  /// Position de la demande dans le parcours de validation.
  int get _etape {
    switch (produit.statutValidation) {
      case 'valide':
        return 2;
      case 'valide_step1':
        return 1;
      default:
        return 0;
    }
  }

  bool get _rejete => produit.statutValidation == 'rejete';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendeurCouleurs.blanc,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VendeurCouleurs.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: produit.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: produit.image,
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _vignetteVide(),
                      )
                    : _vignetteVide(),
              ),
              const SizedBox(width: 11),
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
                    Text(
                      '${produit.prix} FCFA · stock demandé ${produit.stockAlloue}',
                      style: const TextStyle(fontSize: 11.5, color: VendeurCouleurs.gris),
                    ),
                  ],
                ),
              ),
              StatutChip(statut: produit.statutValidation, compact: true),
            ],
          ),
          const SizedBox(height: 14),
          if (_rejete)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VendeurCouleurs.rouge.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Demande rejetée. Modifiez la fiche puis renvoyez-la pour une '
                'nouvelle validation.',
                style: TextStyle(fontSize: 12, color: VendeurCouleurs.rouge, height: 1.35),
              ),
            )
          else
            _progression(),
        ],
      ),
    );
  }

  /// Fil de progression à trois étapes : envoyée → en revue → publiée.
  Widget _progression() {
    const etapes = ['Envoyée', 'En revue', 'Publiée'];
    return Row(
      children: [
        for (var i = 0; i < etapes.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: i <= _etape ? VendeurCouleurs.bleu : VendeurCouleurs.bordure,
              ),
            ),
          Column(
            children: [
              Icon(
                i <= _etape ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 17,
                color: i <= _etape ? VendeurCouleurs.bleu : VendeurCouleurs.bordure,
              ),
              const SizedBox(height: 3),
              Text(
                etapes[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: i <= _etape ? VendeurCouleurs.bleu : VendeurCouleurs.gris,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _vignetteVide() => Container(
        width: 46,
        height: 46,
        color: VendeurCouleurs.fond,
        child: const Icon(Icons.image_outlined, size: 18, color: VendeurCouleurs.gris),
      );
}
