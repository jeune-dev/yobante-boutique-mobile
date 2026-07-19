import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/utils/image_cloudinary.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/promotions_remote_datasource.dart';
import '../../data/models/promotion_model.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
  static const or = Color(0xFFF5C518);
}

/// Promotions d'une section de l'accueil.
///
/// Ouverte en touchant une sous-section : l'accueil ne menait jusqu'ici que
/// vers la liste de *toutes* les promotions, sans moyen de voir celles d'une
/// section en particulier.
class SectionPromotionsPage extends StatefulWidget {
  /// Clé de section : nos_promos_du_moment, a_ne_pas_rater, nos_promos_a_venir.
  final String section;

  /// Titre affiché — celui de la sous-section touchée, à défaut de la section.
  final String titre;

  /// Visuel de la sous-section, repris en tête de page pour la continuité.
  final String? image;

  /// Sous-section ouverte, le cas échéant.
  ///
  /// Renseigné, seuls ses produits sont affichés : les sous-sections d'une même
  /// section montraient sinon toutes la même liste. Laissé nul par le bouton
  /// « voir tout », qui couvre bien la section entière.
  final String? blocPromoId;

  const SectionPromotionsPage({
    super.key,
    required this.section,
    required this.titre,
    this.image,
    this.blocPromoId,
  });

  @override
  State<SectionPromotionsPage> createState() => _SectionPromotionsPageState();
}

class _SectionPromotionsPageState extends State<SectionPromotionsPage> {
  List<PromotionModel> _promotions = [];
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final source = sl<PromotionsRemoteDataSource>();
      final promotions = widget.blocPromoId != null
          ? await source.produitsDuBloc(widget.blocPromoId!)
          : await source.promotionsSection(widget.section);
      if (!mounted) return;
      setState(() {
        _promotions = promotions;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = e.toString();
      });
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
        title: Text(
          widget.titre,
          style: GoogleFonts.sora(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _C.black,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _corps(),
      ),
    );
  }

  Widget _corps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erreur != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.wifi_off_rounded, size: 32, color: _C.sub),
          const SizedBox(height: 10),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Impossible de charger cette section.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: _C.sub, fontSize: 13.5),
              ),
            ),
          ),
          Center(
            child: TextButton(onPressed: _charger, child: const Text('Réessayer')),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (widget.image != null && widget.image!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CachedNetworkImage(
              imageUrl: imageOptimisee(
                widget.image,
                largeur: MediaQuery.of(context).size.width.round(),
              ),
              width: double.infinity,
              height: 170,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(height: 170, color: _C.border),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (_promotions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                const Icon(Icons.local_offer_outlined, size: 30, color: _C.sub),
                const SizedBox(height: 10),
                Text(
                  'Aucune promotion dans cette section pour le moment.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: _C.sub, fontSize: 13.5),
                ),
              ],
            ),
          )
        else
          ..._promotions.map(_carte),
      ],
    );
  }

  Widget _carte(PromotionModel promotion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: promotion.image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageOptimisee(promotion.image, largeur: 68),
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _vignetteVide(),
                  )
                : _vignetteVide(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.libelle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _C.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${promotion.prixPromo} FCFA',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _C.green,
                      ),
                    ),
                    if (promotion.pourcentageReduction > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.or,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '−${promotion.pourcentageReduction} %',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _C.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vignetteVide() => Container(
        width: 68,
        height: 68,
        color: _C.bg,
        child: const Icon(Icons.image_not_supported_outlined, color: _C.sub),
      );
}
