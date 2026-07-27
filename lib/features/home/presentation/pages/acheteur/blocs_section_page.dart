import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yobante/features/promotions/presentation/pages/section_promotions_page.dart';
import '../../../../promotions/data/models/bloc_promo_model.dart';
import '../../../../../core/utils/image_cloudinary.dart';
import 'package:yobante/injection_container.dart';
import '../../../../promotions/data/datasources/promotions_remote_datasource.dart';
import '../../../../promotions/data/models/promotion_model.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
}

class BlocsSectionPage extends StatefulWidget {
  final String section;
  final String titre;
  final List<BlocPromoModel> blocs;

  const BlocsSectionPage({
    super.key,
    required this.section,
    required this.titre,
    required this.blocs,
  });

  @override
  State<BlocsSectionPage> createState() => _BlocsSectionPageState();
}

class _BlocsSectionPageState extends State<BlocsSectionPage> {
  List<PromotionModel> _promotions = [];
  bool _chargement = false;

  @override
  void initState() {
    super.initState();
    if (widget.blocs.isEmpty) {
      _chargerPromotions();
    }
  }

  Future<void> _chargerPromotions() async {
    setState(() => _chargement = true);
    try {
      final source = sl<PromotionsRemoteDataSource>();
      final promos = await source.promotionsSection(widget.section);
      if (mounted) setState(() { _promotions = promos; _chargement = false; });
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.blocs.isEmpty) {
      return _buildPromotionsPage();
    }
    return _buildBlocsPage();
  }

  Widget _buildBlocsPage() {
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
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.blocs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _blocCard(context, widget.blocs[i]),
      ),
    );
  }

  Widget _buildPromotionsPage() {
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
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _promotions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 30, color: _C.sub),
                      const SizedBox(height: 10),
                      Text(
                        'Aucune promotion disponible',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(color: _C.sub, fontSize: 13.5),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _promotions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _promotionCard(context, _promotions[i]),
                ),
    );
  }

  Widget _blocCard(BuildContext context, BlocPromoModel bloc) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SectionPromotionsPage(
            section: widget.section,
            titre: bloc.titre?.isNotEmpty == true
                ? bloc.titre!
                : widget.titre,
            image: bloc.image,
            blocPromoId: bloc.id,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: bloc.image?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: imageOptimisee(
                        bloc.image!,
                        largeur: MediaQuery.of(context).size.width.round(),
                      ),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 180,
                        color: _C.bg,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: _C.sub),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 180,
                      color: _C.bg,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: _C.sub, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bloc.titre ?? 'Bloc promotion',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: _C.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _C.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: _C.white, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promotionCard(BuildContext context, PromotionModel promo) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: promo.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageOptimisee(
                          promo.image,
                          largeur: MediaQuery.of(context).size.width.round(),
                        ),
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 180,
                          color: _C.bg,
                          child: const Icon(Icons.image_not_supported_outlined,
                              color: _C.sub),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 180,
                        color: _C.bg,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: _C.sub, size: 40),
                      ),
              ),
              if (promo.pourcentageReduction > 0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-${promo.pourcentageReduction.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: _C.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.libelle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _C.black,
                  ),
                ),
                const SizedBox(height: 6),
                if ((promo.description ?? '').isNotEmpty)
                  Text(
                    promo.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: _C.sub,
                      height: 1.4,
                    ),
                  ),
                if ((promo.description ?? '').isNotEmpty)
                  const SizedBox(height: 8),
                Row(
                  children: [
                    if ((promo.produitPrix ?? 0.0) > 0)
                      Text(
                        '${(promo.produitPrix ?? 0.0).toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.dmSans(
                          color: _C.sub,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if ((promo.produitPrix ?? 0.0) > 0)
                      const SizedBox(width: 8),
                    Text(
                      '${promo.prixPromo.toStringAsFixed(0)} FCFA',
                      style: GoogleFonts.dmSans(
                        color: _C.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
