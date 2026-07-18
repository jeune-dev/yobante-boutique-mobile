import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../data/models/vendeur_commande_model.dart';
import '../bloc/vendeur_commande_bloc.dart';
import '../widgets/statut_chip.dart';

/// Commandes dans lesquelles figurent les produits du vendeur.
///
/// Une commande peut contenir les produits de plusieurs vendeurs : le backend
/// ne renvoie que les lignes du vendeur courant, et `montantVendeur` ne
/// couvre que ces lignes.
class VendeurCommandesPage extends StatelessWidget {
  const VendeurCommandesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendeurCommandeBloc(tableauBord: sl())..add(LoadCommandesVendeur()),
      child: const _VendeurCommandesVue(),
    );
  }
}

const _filtres = <String, String?>{
  'Toutes': null,
  'À traiter': 'en_attente',
  'En préparation': 'en_preparation',
  'Expédiées': 'expediee',
  'Livrées': 'livree',
};

class _VendeurCommandesVue extends StatelessWidget {
  const _VendeurCommandesVue();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendeurCouleurs.fond,
      appBar: AppBar(
        backgroundColor: VendeurCouleurs.blanc,
        elevation: 0.5,
        foregroundColor: VendeurCouleurs.noir,
        title: const Text('Commandes'),
      ),
      body: Column(
        children: [
          _barreFiltres(context),
          Expanded(
            child: BlocBuilder<VendeurCommandeBloc, VendeurCommandeState>(
              builder: (context, state) {
                if (state is VendeurCommandeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is VendeurCommandeError) {
                  return _erreur(context, state.message);
                }
                if (state is VendeurCommandeLoaded) {
                  if (state.commandes.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune commande pour ce filtre',
                        style: TextStyle(color: VendeurCouleurs.gris),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => context
                        .read<VendeurCommandeBloc>()
                        .add(LoadCommandesVendeur(statut: state.statut)),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      itemCount: state.commandes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _CarteCommande(commande: state.commandes[i]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _barreFiltres(BuildContext context) {
    return BlocBuilder<VendeurCommandeBloc, VendeurCommandeState>(
      builder: (context, state) {
        final actif = state is VendeurCommandeLoaded ? state.statut : null;
        return SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final entree in _filtres.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entree.key),
                    selected: actif == entree.value,
                    onSelected: (_) => context
                        .read<VendeurCommandeBloc>()
                        .add(LoadCommandesVendeur(statut: entree.value)),
                    selectedColor: VendeurCouleurs.bleuClair,
                    backgroundColor: VendeurCouleurs.blanc,
                    side: const BorderSide(color: VendeurCouleurs.bordure),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: actif == entree.value
                          ? VendeurCouleurs.bleu
                          : VendeurCouleurs.gris,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _erreur(BuildContext context, String message) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: VendeurCouleurs.gris),
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.read<VendeurCommandeBloc>().add(LoadCommandesVendeur()),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
}

class _CarteCommande extends StatelessWidget {
  final VendeurCommandeModel commande;
  const _CarteCommande({required this.commande});

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
              Expanded(
                child: Text(
                  commande.reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: VendeurCouleurs.noir,
                  ),
                ),
              ),
              StatutChip(statut: commande.statut, type: StatutType.commande),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              commande.clientNom,
              if (commande.ville != null) commande.ville,
              if (commande.creeLe != null) _date(commande.creeLe!),
            ].join(' · '),
            style: const TextStyle(fontSize: 12, color: VendeurCouleurs.gris),
          ),
          const SizedBox(height: 12),
          for (final ligne in commande.lignes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    '${ligne.quantite}×',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: VendeurCouleurs.bleu,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ligne.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: VendeurCouleurs.noir),
                    ),
                  ),
                  Text(
                    formatFcfa(ligne.sousTotal),
                    style: const TextStyle(fontSize: 12.5, color: VendeurCouleurs.gris),
                  ),
                ],
              ),
            ),
          const Divider(height: 18, color: VendeurCouleurs.bordure),
          Row(
            children: [
              Text(
                '${commande.totalArticles} article${commande.totalArticles > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: VendeurCouleurs.gris),
              ),
              const Spacer(),
              const Text(
                'Votre part : ',
                style: TextStyle(fontSize: 12, color: VendeurCouleurs.gris),
              ),
              Text(
                formatFcfa(commande.montantVendeur),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: VendeurCouleurs.bleu,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
