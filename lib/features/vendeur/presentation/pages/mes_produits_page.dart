import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../injection_container.dart';
import '../bloc/vendeur_produit_bloc.dart';
import 'produit_form_page.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
}

class MesProduitsPage extends StatelessWidget {
  const MesProduitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VendeurProduitBloc>()..add(LoadMesProduits()),
      child: const _MesProduitsView(),
    );
  }
}

class _MesProduitsView extends StatelessWidget {
  const _MesProduitsView();

  Future<void> _ouvrirForm(BuildContext context, {dynamic produit}) async {
    final bloc = context.read<VendeurProduitBloc>();
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProduitFormPage(produit: produit)),
    );
    if (res == true) bloc.add(LoadMesProduits());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Mes produits'),
      ),
      // Remonté au-dessus de la barre de navigation flottante du MainVendeurPage
      // (extendBody: true) : on tient compte de la zone sûre (gestes système).
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 44 + MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton.extended(
          backgroundColor: _C.green,
          foregroundColor: _C.white,
          onPressed: () => _ouvrirForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un produit'),
        ),
      ),
      body: BlocConsumer<VendeurProduitBloc, VendeurProduitState>(
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
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _C.sub)),
                  TextButton(
                    onPressed: () =>
                        context.read<VendeurProduitBloc>().add(LoadMesProduits()),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          if (state is VendeurProduitLoaded) {
            if (state.produits.isEmpty) {
              return const Center(
                child: Text('Aucun produit. Ajoutez-en un !',
                    style: TextStyle(color: _C.sub)),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<VendeurProduitBloc>().add(LoadMesProduits()),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: state.produits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = state.produits[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: _C.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _C.border),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: p.image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: p.image,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _imgFallback(),
                                )
                              : _imgFallback(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.nom,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _C.black)),
                              const SizedBox(height: 2),
                              Text('${p.prix} FCFA',
                                  style: const TextStyle(
                                      color: _C.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.disponible
                                      ? _C.green.withOpacity(0.12)
                                      : const Color(0xFFFDECEC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.disponible ? 'Disponible' : 'Indisponible',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: p.disponible
                                        ? _C.green
                                        : const Color(0xFFE53935),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            final bloc = context.read<VendeurProduitBloc>();
                            if (v == 'edit') {
                              _ouvrirForm(context, produit: p);
                            } else if (v == 'delete') {
                              _confirmerSuppression(context, bloc, p.id);
                            } else if (v == 'toggle') {
                              bloc.add(ToggleDispoProduit(p.id));
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Modifier')),
                            PopupMenuItem(
                                value: 'toggle',
                                child: Text(p.disponible
                                    ? 'Rendre indisponible'
                                    : 'Rendre disponible')),
                            const PopupMenuItem(
                                value: 'delete', child: Text('Supprimer')),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _confirmerSuppression(
      BuildContext context, VendeurProduitBloc bloc, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(SupprimerProduit(id));
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback() => Container(
        width: 60,
        height: 60,
        color: _C.bg,
        child: const Icon(Icons.image_not_supported_outlined, color: _C.sub),
      );
}
