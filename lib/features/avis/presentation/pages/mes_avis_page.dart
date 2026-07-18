import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

/// Avis donnés par l'acheteur connecté (GET /acheteurs/mes-avis).
class MesAvisPage extends StatelessWidget {
  const MesAvisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AvisBloc>()..add(LoadMesAvis()),
      child: const _MesAvisView(),
    );
  }
}

class _MesAvisView extends StatelessWidget {
  const _MesAvisView();

  Future<void> _modifier(BuildContext context, String id, int note, String commentaire) async {
    final commentCtrl = TextEditingController(text: commentaire);
    int nouvelleNote = note;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Modifier mon avis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < nouvelleNote ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setStateDialog(() => nouvelleNote = i + 1),
                  );
                }),
              ),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Commentaire'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    if (res == true && context.mounted) {
      context.read<AvisBloc>().add(
          ModifierAvis(id, note: nouvelleNote, commentaire: commentCtrl.text.trim()));
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
        title: const Text('Mes avis'),
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
                child: Text('Vous n\'avez encore laissé aucun avis',
                    style: TextStyle(color: _C.sub)),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<AvisBloc>().add(LoadMesAvis()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.avis.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final a = state.avis[i];
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
                              child: Text(a.boutiqueNom ?? 'Boutique',
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
                        if (a.reponseVendeur != null && a.reponseVendeur!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _C.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Réponse du vendeur : ${a.reponseVendeur}',
                                style: const TextStyle(color: _C.sub, fontSize: 12)),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (a.createdAt != null)
                              Expanded(
                                child: Text(
                                    DateFormat('dd/MM/yyyy').format(a.createdAt!),
                                    style: const TextStyle(color: _C.sub, fontSize: 11)),
                              ),
                            TextButton(
                              onPressed: () =>
                                  _modifier(context, a.id, a.note, a.commentaire),
                              child: const Text('Modifier'),
                            ),
                            TextButton(
                              onPressed: () => context
                                  .read<AvisBloc>()
                                  .add(SupprimerAvis(a.id)),
                              child: const Text('Supprimer',
                                  style: TextStyle(color: Colors.red)),
                            ),
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
}
