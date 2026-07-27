import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final reponse = await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répondre à cet avis',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: ctrl,
              maxLines: 4,
              style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Écrivez votre réponse...',
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
                    onPressed: () => Navigator.pop(ctx),
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
                    onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF163A9E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Envoyer',
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
