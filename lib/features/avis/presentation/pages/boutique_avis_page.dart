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

/// Avis publics d'une boutique (GET /avis/:boutiqueId) + création d'un
/// nouvel avis par l'acheteur connecté (POST /avis).
class BoutiqueAvisPage extends StatelessWidget {
  final String boutiqueId;
  final String? boutiqueNom;
  const BoutiqueAvisPage({super.key, required this.boutiqueId, this.boutiqueNom});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AvisBloc>()..add(LoadAvisBoutique(boutiqueId)),
      child: _BoutiqueAvisView(boutiqueId: boutiqueId, boutiqueNom: boutiqueNom),
    );
  }
}

class _BoutiqueAvisView extends StatefulWidget {
  final String boutiqueId;
  final String? boutiqueNom;
  const _BoutiqueAvisView({required this.boutiqueId, this.boutiqueNom});

  @override
  State<_BoutiqueAvisView> createState() => _BoutiqueAvisViewState();
}

class _BoutiqueAvisViewState extends State<_BoutiqueAvisView> {
  int _note = 5;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _envoyer() {
    if (_commentCtrl.text.trim().isEmpty) return;
    context.read<AvisBloc>().add(CreerAvis(
          note: _note,
          commentaire: _commentCtrl.text.trim(),
          boutiqueId: widget.boutiqueId,
        ));
    _commentCtrl.clear();
    setState(() => _note = 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: Text(widget.boutiqueNom ?? 'Avis de la boutique'),
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
          final loading = state is AvisLoading;
          final avis = state is AvisListeLoaded ? state.avis : const [];
          return Column(
            children: [
              Expanded(
                child: avis.isEmpty && !loading
                    ? const Center(
                        child: Text('Aucun avis pour cette boutique',
                            style: TextStyle(color: _C.sub)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: avis.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final a = avis[i];
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
                                              fontWeight: FontWeight.w700,
                                              color: _C.black)),
                                    ),
                                    Row(
                                      children: List.generate(
                                          5,
                                          (i) => Icon(
                                                i < a.note
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                size: 14,
                                                color: Colors.amber,
                                              )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(a.commentaire),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _C.white,
                  border: Border(top: BorderSide(color: _C.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (i) {
                          return IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              i < _note ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () => setState(() => _note = i + 1),
                          );
                        }),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Laisser un avis...',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: _C.green),
                            onPressed: loading ? null : _envoyer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
