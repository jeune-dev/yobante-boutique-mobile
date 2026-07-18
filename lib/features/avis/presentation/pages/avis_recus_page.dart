import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../bloc/avis_bloc.dart';
import '../bloc/avis_event.dart';
import '../bloc/avis_state.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
}

/// Avis reçus par le vendeur (GET /vendeur/mes-avis) + réponse
/// (POST /vendeur/avis/:avisId/repondre).
class AvisRecusPage extends StatelessWidget {
  const AvisRecusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AvisBloc>()..add(LoadAvisRecus()),
      child: const _AvisRecusView(),
    );
  }
}

class _AvisRecusView extends StatelessWidget {
  const _AvisRecusView();

  Future<void> _repondre(BuildContext context, String avisId) async {
    final ctrl = TextEditingController();
    final reponse = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Répondre à cet avis'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Votre réponse'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Envoyer')),
        ],
      ),
    );
    if (reponse != null && reponse.isNotEmpty && context.mounted) {
      context.read<AvisBloc>().add(RepondreAvis(avisId, reponse));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Avis reçus'),
      ),
      body: BlocConsumer<AvisBloc, AvisState>(
        listener: (context, state) {
          if (state is AvisError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AvisLoading || state is AvisInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AvisListeLoaded) {
            if (state.avis.isEmpty) {
              return const Center(
                child: Text('Aucun avis reçu pour le moment',
                    style: TextStyle(color: _C.sub)),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<AvisBloc>().add(LoadAvisRecus()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.avis.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final a = state.avis[i];
                  final dejaRepondu =
                      a.reponseVendeur != null && a.reponseVendeur!.isNotEmpty;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _C.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(a.acheteurNom ?? 'Client',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, color: _C.black)),
                            ),
                            Row(
                              children: List.generate(
                                  5,
                                  (i) => Icon(
                                        i < a.note ? Icons.star : Icons.star_border,
                                        size: 16,
                                        color: Colors.amber,
                                      )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(a.commentaire, style: const TextStyle(color: _C.black)),
                        const SizedBox(height: 8),
                        if (dejaRepondu)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _C.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Votre réponse : ${a.reponseVendeur}',
                                style: const TextStyle(color: _C.sub, fontSize: 12)),
                          )
                        else
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _repondre(context, a.id),
                              icon: const Icon(Icons.reply, size: 16, color: _C.green),
                              label: const Text('Répondre',
                                  style: TextStyle(color: _C.green)),
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
