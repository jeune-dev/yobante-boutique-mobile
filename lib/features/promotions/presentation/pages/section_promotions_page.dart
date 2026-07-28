import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/utils/image_cloudinary.dart';
import '../../../../core/widgets/barre_boutique.dart';
import '../../../../injection_container.dart';
import '../../../home/presentation/widgets/produit_card.dart';
import '../../data/datasources/promotions_remote_datasource.dart';
import '../../data/models/promotion_model.dart';
import '../widgets/promotion_card.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const black = Color(0xFF1A1A1A);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
}

/// Promotions d'une section de l'accueil.
///
/// Ouverte en touchant une sous-section : l'accueil ne menait jusqu'ici que
/// vers la liste de *toutes* les promotions, sans moyen de voir celles d'une
/// section en particulier.
///
/// Page pleine : la barre de navigation du bas laisse la place à la
/// [BarreBoutique], qui porte le retour, la recherche, le panier et le menu.
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

  final _recherche = TextEditingController();
  String _filtre = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
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

  /// Filtrage local : la liste d'une section est courte, inutile de repasser
  /// par le réseau à chaque frappe.
  List<PromotionModel> get _visibles {
    if (_filtre.isEmpty) return _promotions;
    final terme = _filtre.toLowerCase();
    return _promotions
        .where((p) => p.libelle.toLowerCase().contains(terme))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: BarreBoutique(
        controleurRecherche: _recherche,
        onRecherche: (valeur) => setState(() => _filtre = valeur.trim()),
        indication: 'Rechercher dans ${widget.titre}',
      ),
      body: RefreshIndicator(
        color: _C.green,
        onRefresh: _charger,
        child: _corps(),
      ),
    );
  }

  Widget _corps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: _C.green));
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

    final promotions = _visibles;

    return CustomScrollView(
      // Le tirer-pour-rafraîchir doit rester possible même quand la section
      // tient sur un écran.
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _entete()),
        if (promotions.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  const Icon(Icons.local_offer_outlined, size: 30, color: _C.sub),
                  const SizedBox(height: 10),
                  Text(
                    _filtre.isEmpty
                        ? 'Aucune promotion dans cette section pour le moment.'
                        : 'Aucun résultat pour « $_filtre ».',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(color: _C.sub, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            sliver: SliverGrid(
              gridDelegate: grilleProduits,
              delegate: SliverChildBuilderDelegate(
                (_, i) => PromotionCard(promotion: promotions[i]),
                childCount: promotions.length,
              ),
            ),
          ),
      ],
    );
  }

  /// Bandeau de la sous-section : son visuel, puis son titre.
  Widget _entete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.image != null && widget.image!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              // Aucune hauteur imposée : la bannière garde ses proportions
              // d'origine et s'affiche en entier. Un cadrage en `cover` sur une
              // hauteur fixe amputait le visuel envoyé par l'administration.
              child: CachedNetworkImage(
                imageUrl: imageOptimisee(
                  widget.image,
                  largeur: MediaQuery.of(context).size.width.round(),
                ),
                width: double.infinity,
                fit: BoxFit.fitWidth,
                placeholder: (_, __) =>
                    Container(height: 150, color: _C.border),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
          child: Text(
            widget.titre,
            style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _C.black,
            ),
          ),
        ),
      ],
    );
  }
}
