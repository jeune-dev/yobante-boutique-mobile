import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../injection_container.dart';
import '../../../home/presentation/widgets/produit_card.dart';
import '../bloc/promotions_bloc.dart';
import '../bloc/promotions_event.dart';
import '../bloc/promotions_state.dart';
import '../widgets/promotion_card.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
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
            return const Center(child: CircularProgressIndicator(color: _C.green));
          }
          if (state is PromotionsLoaded) {
            if (state.promotions.isEmpty) {
              return Center(
                child: Text('Aucune promotion active pour le moment',
                    style: GoogleFonts.dmSans(color: _C.sub)),
              );
            }
            return RefreshIndicator(
              color: _C.green,
              onRefresh: () async =>
                  context.read<PromotionsBloc>().add(LoadPromotionsActives()),
              // Même présentation que le reste de la boutique : grille de
              // deux colonnes, chaque produit commandable depuis la liste.
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: grilleProduits,
                itemCount: state.promotions.length,
                itemBuilder: (context, i) =>
                    PromotionCard(promotion: state.promotions[i]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
