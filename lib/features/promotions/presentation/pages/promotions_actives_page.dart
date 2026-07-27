import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
}

/// Promotions actives, publiques (GET /promotions/actives) — affichées côté
/// accueil acheteur.
class PromotionsActivesPage extends StatelessWidget {
  const PromotionsActivesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PromotionsBloc>()..add(LoadPromotionsActives()),
      child: const _PromotionsActivesView(),
    );
  }
}

class _PromotionsActivesView extends StatelessWidget {
  const _PromotionsActivesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        centerTitle: true,
        title: Text('Promotions',
            style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w800, color: _C.black)),
      ),
      body: BlocConsumer<PromotionsBloc, PromotionsState>(
        listener: (context, state) {
          if (state is PromotionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is PromotionsLoading || state is PromotionsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PromotionsLoaded) {
            if (state.promotions.isEmpty) {
              return const Center(
                child: Text('Aucune promotion active pour le moment',
                    style: TextStyle(color: _C.sub)),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<PromotionsBloc>().add(LoadPromotionsActives()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.promotions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final p = state.promotions[i];
                  final prixOriginal = p.produitPrix ?? 0.0;
                  final prixPromo = p.prixPromo;
                  final reduction = p.pourcentageReduction ?? 0.0;

                  return Container(
                    decoration: BoxDecoration(
                      color: _C.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: (p.produitImage ?? '').isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: p.produitImage!,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: _C.bg,
                                        child: const Icon(Icons.local_offer_outlined,
                                            color: _C.sub, size: 40),
                                      ),
                                    )
                                  : Container(
                                      width: double.infinity,
                                      height: 180,
                                      color: _C.bg,
                                      child: const Icon(Icons.local_offer_outlined,
                                          color: _C.sub, size: 40),
                                    ),
                            ),
                            if (reduction > 0)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53E3E),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-${reduction.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: _C.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.produitNom ?? 'Produit sans nom',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: _C.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (prixOriginal > 0)
                                    Text(
                                      '${prixOriginal.toStringAsFixed(0)} FCFA',
                                      style: const TextStyle(
                                        color: _C.sub,
                                        fontSize: 12,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  if (prixOriginal > 0) const SizedBox(width: 8),
                                  Text(
                                    '${prixPromo.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      color: _C.green,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _C.bg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 14, color: _C.sub),
                                    const SizedBox(width: 6),
                                    if (p.dateDebut != null)
                                      Text(
                                        'Du ${DateFormat('dd/MM').format(p.dateDebut!)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _C.sub,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (p.dateFin != null)
                                Row(
                                  children: [
                                    const Icon(Icons.schedule,
                                        size: 14, color: _C.sub),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Jusqu\'au ${DateFormat('dd/MM/yyyy').format(p.dateFin!)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _C.sub,
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
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
