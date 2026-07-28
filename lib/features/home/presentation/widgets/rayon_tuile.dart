import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/image_cloudinary.dart';

class _C {
  static const green   = Color(0xFF163A9E);
  static const black   = Color(0xFF1A1A1A);
  static const white   = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F9FC);
  static const border  = Color(0xFFEDF0F7);
  static const label   = Color(0xFF9AA3B2);
}

/// Grille des rayons de l'accueil : trois colonnes de vignettes carrées.
///
/// Le rapport laisse la place au libellé sous la vignette — la photo occupe le
/// carré, le texte vit en dehors.
const SliverGridDelegateWithFixedCrossAxisCount grilleRayons =
    SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 3,
  crossAxisSpacing: 12,
  mainAxisSpacing: 14,
  childAspectRatio: 0.74,
);

/// Vignette d'un rayon : photo dans une carte blanche, libellé en dessous.
///
/// Le visuel est cadré en `cover` sur un carré, exactement le cadrage préparé
/// depuis le tableau de bord : ce qui est recadré là-bas est ce qui s'affiche
/// ici, sans recadrage supplémentaire.
class RayonTuile extends StatelessWidget {
  final String nom;
  final String? image;

  /// Repli quand aucun visuel n'a encore été téléversé.
  final IconData icone;

  final VoidCallback onTap;

  const RayonTuile({
    super.key,
    required this.nom,
    required this.onTap,
    this.image,
    this.icone = Icons.category_rounded,
  });

  bool get _aUneImage => image != null && image!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _C.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _aUneImage
                  ? CachedNetworkImage(
                      imageUrl: imageOptimisee(image, largeur: 200),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: _C.surface),
                      errorWidget: (_, __, ___) => _repli(),
                    )
                  : _repli(),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            nom,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _C.black,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _repli() => Container(
        color: _C.surface,
        alignment: Alignment.center,
        child: Icon(icone, color: _C.label, size: 30),
      );
}
