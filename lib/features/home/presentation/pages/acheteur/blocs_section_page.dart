import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yobante/features/promotions/presentation/pages/section_promotions_page.dart';
import '../../../../promotions/data/models/bloc_promo_model.dart';
import '../../../../../core/utils/image_cloudinary.dart';
import '../../../../../core/widgets/barre_boutique.dart';
import 'package:yobante/injection_container.dart';
import '../../../../promotions/data/datasources/promotions_remote_datasource.dart';
import '../../../../promotions/data/models/promotion_model.dart';
import '../../../../promotions/presentation/widgets/promotion_card.dart';
import '../../widgets/produit_card.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
}

/// Sous-sections d'une section de l'accueil, ou directement ses promotions
/// quand l'administration n'en a défini aucune.
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

  final _recherche = TextEditingController();
  String _filtre = '';

  @override
  void initState() {
    super.initState();
    if (widget.blocs.isEmpty) {
      _chargerPromotions();
    }
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
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

  /// Filtrage local, sur le libellé des sous-sections ou des promotions.
  bool _correspond(String libelle) =>
      _filtre.isEmpty || libelle.toLowerCase().contains(_filtre.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: BarreBoutique(
        controleurRecherche: _recherche,
        onRecherche: (valeur) => setState(() => _filtre = valeur.trim()),
        indication: 'Rechercher dans ${widget.titre}',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              widget.titre,
              style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.black,
              ),
            ),
          ),
          Expanded(
            child: widget.blocs.isEmpty ? _corpsPromotions() : _corpsBlocs(),
          ),
        ],
      ),
    );
  }

  Widget _corpsBlocs() {
    final blocs = widget.blocs
        .where((b) => _correspond(b.titre ?? ''))
        .toList();
    if (blocs.isEmpty) return _vide('Aucune sous-section');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: blocs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _blocCard(context, blocs[i]),
    );
  }

  Widget _corpsPromotions() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: _C.green));
    }
    final promotions =
        _promotions.where((p) => _correspond(p.libelle)).toList();
    if (promotions.isEmpty) return _vide('Aucune promotion disponible');

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      gridDelegate: grilleProduits,
      itemCount: promotions.length,
      itemBuilder: (_, i) => PromotionCard(promotion: promotions[i]),
    );
  }

  Widget _vide(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_offer_outlined, size: 30, color: _C.sub),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: _C.sub, fontSize: 13.5),
          ),
        ],
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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comme les bannières de section : hauteur libre, l'image garde
            // ses proportions et n'est pas rognée.
            bloc.image?.isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: imageOptimisee(
                      bloc.image!,
                      largeur: MediaQuery.of(context).size.width.round(),
                    ),
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    placeholder: (_, __) => Container(
                      height: 160,
                      color: _C.bg,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: _C.sub),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 160,
                    color: _C.bg,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: _C.sub, size: 40),
                  ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      bloc.titre ?? 'Bloc promotion',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _C.black,
                      ),
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
}
