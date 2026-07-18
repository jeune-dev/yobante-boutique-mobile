import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../home/presentation/pages/vendeur/profil_page.dart';
import 'statut_chip.dart';

/// Barre supérieure de l'espace vendeur.
///
/// Reprend la présentation de l'entête client connecté : pictogramme à gauche,
/// cloche de notifications, puis avatar aux initiales qui ouvre le profil —
/// le profil n'occupe donc plus un onglet de la barre du bas.
class EnteteVendeur extends StatelessWidget {
  final User? user;
  const EnteteVendeur({super.key, this.user});

  String get _initiales {
    if (user == null) return '?';
    final p = user!.prenom.isNotEmpty ? user!.prenom[0] : '';
    final n = user!.nom.isNotEmpty ? user!.nom[0] : '';
    final initiales = '$p$n'.toUpperCase();
    return initiales.isEmpty ? '?' : initiales;
  }

  @override
  Widget build(BuildContext context) {
    final photo = user?.photoProfil;
    final aUnePhoto = photo != null && photo.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: VendeurCouleurs.blanc,
        border: Border(bottom: BorderSide(color: VendeurCouleurs.bordure, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
          child: Row(
            children: [
              Image.asset(
                'assets/images/Logo Yobante pictogramme - Version.png',
                height: 76,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              _icone(
                icone: Icons.notifications_none_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProfilPage(user: user)),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: VendeurCouleurs.bleuClair,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VendeurCouleurs.bleu.withValues(alpha: 0.15)),
                  ),
                  child: aUnePhoto
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            photo,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _pastilleInitiales(),
                          ),
                        )
                      : _pastilleInitiales(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pastilleInitiales() => Center(
        child: Text(
          _initiales,
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: VendeurCouleurs.bleu,
          ),
        ),
      );

  Widget _icone({required IconData icone, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: VendeurCouleurs.fond,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, color: VendeurCouleurs.bleu, size: 22),
        ),
      );
}
