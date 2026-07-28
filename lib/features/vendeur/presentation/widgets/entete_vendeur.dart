import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../injection_container.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/widgets/cloche_notifications.dart';
import '../../../../core/utils/image_asset.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../compte/presentation/bloc/compte_bloc.dart';
import '../../../compte/presentation/bloc/compte_event.dart';
import '../../../compte/presentation/bloc/compte_state.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../home/presentation/pages/vendeur/profil_page.dart';
import 'statut_chip.dart';

/// Barre supérieure de l'espace vendeur.
///
/// Reprend la présentation de l'entête client connecté : pictogramme à gauche,
/// cloche de notifications, puis avatar aux initiales qui ouvre le profil —
/// le profil n'occupe donc plus un onglet de la barre du bas.
class EnteteVendeur extends StatefulWidget {
  final User? user;
  const EnteteVendeur({super.key, this.user});

  @override
  State<EnteteVendeur> createState() => _EnteteVendeurState();
}

class _EnteteVendeurState extends State<EnteteVendeur> {
  final CompteBloc _compteBloc = sl<CompteBloc>();
  StreamSubscription? _compteSub;

  /// Utilisateur chargé depuis l'API quand la page n'en reçoit pas : à la
  /// restauration de session, le splash ouvre l'espace vendeur sans transmettre
  /// d'utilisateur, et l'avatar afficherait sinon un point d'interrogation.
  User? _userCharge;

  User? get _user => widget.user ?? _userCharge;

  @override
  void initState() {
    super.initState();
    if (widget.user == null) {
      _compteSub = _compteBloc.stream.listen((state) {
        if (state is CompteLoaded && mounted) {
          setState(() => _userCharge = state.user);
        }
      });
      sl<TokenService>().isAuthenticated.then((connecte) {
        if (connecte) _compteBloc.add(LoadCompte());
      });
    }
  }

  @override
  void dispose() {
    _compteSub?.cancel();
    super.dispose();
  }

  /// Deux premières lettres du nom de famille (« GUEYE » → « GU »).
  /// Repli sur le prénom si le nom manque.
  String get _initiales {
    final nom = _user?.nom.trim() ?? '';
    if (nom.length >= 2) return nom.substring(0, 2).toUpperCase();
    if (nom.length == 1) return nom.toUpperCase();

    final prenom = _user?.prenom.trim() ?? '';
    if (prenom.length >= 2) return prenom.substring(0, 2).toUpperCase();
    if (prenom.length == 1) return prenom.toUpperCase();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final photo = _user?.photoProfil;
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
              imageAsset(
                context,
                'assets/images/Logo Yobante pictogramme - Version.png',
                hauteur: 76,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              ClocheNotifications(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProfilPage(user: _user)),
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
                            cacheWidth: (40 *
                                    MediaQuery.of(context).devicePixelRatio)
                                .round(),
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

  Widget _pastilleInitiales() {
    final initiales = _initiales;
    // Tant que le profil n'est pas revenu, une icône neutre vaut mieux qu'un
    // caractère de remplissage.
    if (initiales.isEmpty) {
      return const Icon(Icons.person_outline_rounded,
          color: VendeurCouleurs.bleu, size: 22);
    }
    return Center(
      child: Text(
        initiales,
        style: GoogleFonts.sora(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: VendeurCouleurs.bleu,
        ),
      ),
    );
  }

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
