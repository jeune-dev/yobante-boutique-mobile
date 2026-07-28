import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../injection_container.dart';
import '../../../data/datasources/produit_remote_datasource.dart';
import '../../../data/models/boutique_model.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/models/rayon_model.dart';
import '../../widgets/produit_card.dart';
import 'boutiques_page.dart';

class _C {
  static const green      = Color(0xFF163A9E);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const border     = Color(0xFFDDE3EF);
  static const label      = Color(0xFF9AA3B2);
}

/// Page « Rechercher » : filtres de rayons en tête, catalogue en dessous.
///
/// Les filtres portent sur les rayons **du serveur**, ceux que l'administration
/// gère et que l'accueil affiche déjà. La page listait auparavant un catalogue
/// écrit en dur, sans rapport avec le vrai rangement de la boutique.
class RechercheGlobalePage extends StatefulWidget {
  const RechercheGlobalePage({super.key});

  @override
  State<RechercheGlobalePage> createState() => _RechercheGlobalePageState();
}

class _RechercheGlobalePageState extends State<RechercheGlobalePage> {
  final _ds = sl<ProduitRemoteDataSource>();
  final _ctrl = TextEditingController();

  List<RayonModel> _rayons = [];

  /// Rayon filtré. Nul = « Tous ».
  String? _rayonId;

  /// Sous-rayon filtré, dans le rayon courant. Nul = tout le rayon.
  String? _sousRayonId;

  List<ProduitModel> _produits = [];
  List<BoutiqueModel> _boutiques = [];

  bool _chargement = true;
  String? _erreur;

  /// Frappe au clavier : on laisse le doigt finir avant d'interroger le serveur.
  Timer? _saisie;

  RayonModel? get _rayonCourant {
    if (_rayonId == null) return null;
    for (final r in _rayons) {
      if (r.id == _rayonId) return r;
    }
    return null;
  }

  String get _recherche => _ctrl.text.trim();

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  @override
  void dispose() {
    _saisie?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _initialiser() async {
    // Les filtres d'abord : la barre doit s'afficher même si le catalogue tarde.
    try {
      final rayons = await _ds.getRayons();
      if (mounted) setState(() => _rayons = rayons);
    } catch (_) {/* filtres masqués, la recherche reste utilisable */}
    await _charger();
  }

  /// Recharge la liste selon le filtre et la recherche courants.
  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      // Une recherche texte prime sur le filtre : elle balaie tout le catalogue,
      // produits et boutiques.
      if (_recherche.isNotEmpty && _rayonId == null) {
        final res = await _ds.rechercheGlobale(_recherche);
        if (!mounted) return;
        setState(() {
          _produits = res.produits;
          _boutiques = res.boutiques;
          _chargement = false;
        });
        return;
      }

      final List<ProduitModel> produits;
      if (_sousRayonId != null) {
        produits = (await _ds.getProduitsDuSousRayon(
          _sousRayonId!,
          search: _recherche.isEmpty ? null : _recherche,
          limit: 40,
        ))
            .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (_rayonId != null) {
        produits = (await _ds.getProduitsDuRayon(
          _rayonId!,
          search: _recherche.isEmpty ? null : _recherche,
          limit: 40,
        ))
            .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        produits = await _ds.getProduits();
      }

      if (!mounted) return;
      setState(() {
        _produits = produits;
        _boutiques = const [];
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Chargement impossible';
        _chargement = false;
      });
    }
  }

  void _surSaisie(String _) {
    setState(() {});
    _saisie?.cancel();
    _saisie = Timer(const Duration(milliseconds: 400), _charger);
  }

  void _choisirRayon(String? id) {
    if (_rayonId == id) return;
    setState(() {
      _rayonId = id;
      _sousRayonId = null;
    });
    _charger();
  }

  void _choisirSousRayon(String? id) {
    if (_sousRayonId == id) return;
    setState(() => _sousRayonId = id);
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    final rayon = _rayonCourant;
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Center(
                child: Text('Rechercher',
                    style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _C.black)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _barreRecherche(),
            ),

            // ── Filtres : rayons, puis sous-rayons du rayon choisi ──────────
            if (_rayons.isNotEmpty) _filtresRayons(),
            if (rayon != null && rayon.sousRayons.isNotEmpty) ...[
              const SizedBox(height: 8),
              _filtresSousRayons(rayon),
            ],
            const SizedBox(height: 10),

            Expanded(child: _corps()),
          ],
        ),
      ),
    );
  }

  // ── Recherche ──────────────────────────────────────────────────────────────
  Widget _barreRecherche() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: _C.label, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: _surSaisie,
              onSubmitted: (_) => _charger(),
              textInputAction: TextInputAction.search,
              cursorColor: _C.green,
              style: GoogleFonts.dmSans(
                  fontSize: 14.5, color: _C.black, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Trouver un article ou une offre',
                hintStyle:
                    GoogleFonts.dmSans(fontSize: 14, color: _C.label),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_recherche.isNotEmpty)
            GestureDetector(
              onTap: () {
                _ctrl.clear();
                _charger();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close_rounded, color: _C.label, size: 19),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }

  // ── Filtres ────────────────────────────────────────────────────────────────
  Widget _filtresRayons() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _rayons.length + 1, // +1 : « Tous »
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _puce('Tous', _rayonId == null, () => _choisirRayon(null));
          }
          final r = _rayons[i - 1];
          return _puce(r.nom, _rayonId == r.id, () => _choisirRayon(r.id));
        },
      ),
    );
  }

  Widget _filtresSousRayons(RayonModel rayon) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rayon.sousRayons.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _puce('Tout le rayon', _sousRayonId == null,
                () => _choisirSousRayon(null),
                secondaire: true);
          }
          final sr = rayon.sousRayons[i - 1];
          return _puce(sr.nom, _sousRayonId == sr.id,
              () => _choisirSousRayon(sr.id),
              secondaire: true);
        },
      ),
    );
  }

  Widget _puce(String libelle, bool actif, VoidCallback onTap,
      {bool secondaire = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
            horizontal: secondaire ? 12 : 14, vertical: secondaire ? 6 : 8),
        decoration: BoxDecoration(
          color: actif ? _C.green : _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: actif ? _C.green : _C.border, width: 1.4),
        ),
        child: Text(
          libelle,
          style: GoogleFonts.dmSans(
            fontSize: secondaire ? 11.5 : 12.5,
            fontWeight: FontWeight.w600,
            color: actif ? _C.white : _C.black,
          ),
        ),
      ),
    );
  }

  // ── Corps ──────────────────────────────────────────────────────────────────
  Widget _corps() {
    if (_chargement) {
      return const Center(
          child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5));
    }
    if (_erreur != null) {
      return _message(_erreur!, action: _charger);
    }
    if (_produits.isEmpty && _boutiques.isEmpty) {
      return _message(_recherche.isEmpty
          ? 'Aucun produit dans cette sélection'
          : 'Aucun résultat pour « $_recherche »');
    }

    return RefreshIndicator(
      color: _C.green,
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_boutiques.isNotEmpty) ...[
            _titreSection('Boutiques (${_boutiques.length})'),
            ..._boutiques.map(_tuileBoutique),
            const SizedBox(height: 16),
          ],
          if (_produits.isNotEmpty) ...[
            _titreSection('Produits (${_produits.length})'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: grilleProduits,
              itemCount: _produits.length,
              itemBuilder: (_, i) => ProduitCard(produit: _produits[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _message(String texte, {VoidCallback? action}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(texte,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: _C.label)),
              if (action != null)
                TextButton(onPressed: action, child: const Text('Réessayer')),
            ],
          ),
        ),
      );

  Widget _titreSection(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
        child: Text(t,
            style: GoogleFonts.sora(
                fontSize: 15, fontWeight: FontWeight.w700, color: _C.black)),
      );

  Widget _tuileBoutique(BoutiqueModel b) {
    final aUnLogo = b.logo != null && b.logo!.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BoutiqueDetailPage(boutique: b)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: aUnLogo
                  ? Image.network(b.logo!,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _logoParDefaut())
                  : _logoParDefaut(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _C.black)),
                  if (b.localisation.isNotEmpty)
                    Text(b.localisation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: _C.label)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.label),
          ],
        ),
      ),
    );
  }

  Widget _logoParDefaut() => Container(
        width: 46,
        height: 46,
        color: _C.bg,
        child: const Icon(Icons.storefront_rounded, color: _C.green, size: 22),
      );
}
