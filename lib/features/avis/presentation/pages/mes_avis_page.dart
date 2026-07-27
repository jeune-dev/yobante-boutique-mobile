import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import '../../../../core/widgets/app_message.dart';
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
    final res = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modifier mon avis',
                  style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Note',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setStateDialog(() => nouvelleNote = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          i < nouvelleNote ? Icons.star : Icons.star_border,
                          color: i < nouvelleNote ? Colors.amber : const Color(0xFFDDE3EF),
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                Text(
                  'Commentaire',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentCtrl,
                  maxLines: 4,
                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Écrivez votre commentaire...',
                    hintStyle: GoogleFonts.dmSans(color: const Color(0xFFC2C9D6)),
                    filled: true,
                    fillColor: const Color(0xFFF7F9FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDDE3EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDDE3EF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF163A9E), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF163A9E),
                          side: const BorderSide(color: Color(0xFFDDE3EF)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF163A9E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Enregistrer',
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            AppMessage.error(context, state.message);
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
