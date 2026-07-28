import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../../../../injection_container.dart';
import '../../../data/datasources/produit_remote_datasource.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/models/rayon_model.dart';
import '../../../../commande/data/services/panier_service.dart';
import '../../../../commande/presentation/pages/panier_page.dart';
import '../../widgets/produit_card.dart';

class _C {
  static const green      = Color(0xFF163A9E);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const border     = Color(0xFFDDE3EF);
  static const label      = Color(0xFF9AA3B2);
  static const sub        = Color(0xFF6B7280);
}

/// Page produits d'un rayon API.
/// Affiche les sous-rayons comme filtres horizontaux, charge les produits
/// depuis l'API avec pagination et recherche.
class RayonProduitsPage extends StatefulWidget {
  final RayonModel rayon;

  const RayonProduitsPage({super.key, required this.rayon});

  @override
  State<RayonProduitsPage> createState() => _RayonProduitsPageState();
}

class _RayonProduitsPageState extends State<RayonProduitsPage> {
  final _ds     = sl<ProduitRemoteDataSource>();

  List<ProduitModel> _produits   = [];
  bool               _loading    = true;
  bool               _loadingMore = false;
  String?            _error;
  String?            _selectedSousRayonId;
  int                _page       = 1;
  bool               _hasMore    = true;

  final _searchCtrl    = TextEditingController();
  final _scrollCtrl    = ScrollController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      _load(reset: true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _page = 1; _hasMore = true; _produits = []; });
    }
    try {
      final search = _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();
      List<dynamic> raw;
      if (_selectedSousRayonId != null) {
        raw = await _ds.getProduitsDuSousRayon(
          _selectedSousRayonId!,
          search: search,
          page: _page,
          limit: 20,
        );
      } else {
        raw = await _ds.getProduitsDuRayon(
          widget.rayon.id,
          search: search,
          page: _page,
          limit: 20,
        );
      }
      final parsed = raw
          .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        if (reset) {
          _produits = parsed;
        } else {
          _produits.addAll(parsed);
        }
        _hasMore  = parsed.length >= 20;
        _loading  = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Chargement impossible'; _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() { _loadingMore = true; _page++; });
    await _load();
  }

  void _selectSousRayon(String? id) {
    if (_selectedSousRayonId == id) return;
    setState(() => _selectedSousRayonId = id);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.rayon.nom,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.sora(
              fontSize: 16, fontWeight: FontWeight.w800, color: _C.black),
        ),
        actions: [
          IconButton(
            icon: ListenableBuilder(
              listenable: sl<PanierService>(),
              builder: (_, __) {
                final n = sl<PanierService>().nombreArticles;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (n > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: _C.green,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            '$n',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PanierPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barre de recherche ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search_rounded, size: 20, color: _C.green.withOpacity(0.6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.dmSans(fontSize: 14, color: _C.black, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Rechercher dans ${widget.rayon.nom}…',
                        hintStyle: GoogleFonts.dmSans(
                            fontSize: 14, color: _C.label, fontWeight: FontWeight.w400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _load(reset: true),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        _load(reset: true);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: _C.green.withOpacity(0.5)),
                      ),
                    ),
                  if (_searchCtrl.text.isEmpty)
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),

          // ── Filtres sous-rayons ────────────────────────────────────────
          if (widget.rayon.sousRayons.isNotEmpty)
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.rayon.sousRayons.length + 1, // +1 pour "Tous"
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    final selected = _selectedSousRayonId == null;
                    return _buildChip('Tous', selected,
                        () => _selectSousRayon(null));
                  }
                  final sr = widget.rayon.sousRayons[i - 1];
                  final selected = _selectedSousRayonId == sr.id;
                  return _buildChip(sr.nom, selected,
                      () => _selectSousRayon(sr.id));
                },
              ),
            ),
          if (widget.rayon.sousRayons.isNotEmpty) const SizedBox(height: 8),

          // ── Contenu ────────────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _C.green : _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _C.green : _C.border, width: 1.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? _C.white : _C.sub,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5));
    }
    if (_error != null) {
      return _emptyState(Icons.error_outline_rounded, _error!, retry: true);
    }
    if (_produits.isEmpty) {
      return _emptyState(Icons.inventory_2_outlined,
          'Aucun produit dans ce rayon pour le moment');
    }
    return RefreshIndicator(
      color: _C.green,
      onRefresh: () => _load(reset: true),
      child: GridView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
        gridDelegate: grilleProduits,
        itemCount: _produits.length + (_loadingMore ? 2 : 0),
        itemBuilder: (_, i) {
          if (i >= _produits.length) {
            return Container(
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.border),
              ),
              child: const Center(
                  child: CircularProgressIndicator(
                      color: _C.green, strokeWidth: 2)),
            );
          }
          return ProduitCard(
            produit: _produits[i],
          );
        },
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: _C.label),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 14, color: _C.sub)),
            if (retry) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _load(reset: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: _C.green,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('Réessayer',
                      style: GoogleFonts.dmSans(
                          color: _C.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
