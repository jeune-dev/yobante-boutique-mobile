import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yobante/features/auth/domain/entities/user.dart';

import '../../../../injection_container.dart';
import '../../../home/data/models/produit_model.dart';
import '../../../vendeur/data/datasources/vendeur_produit_datasource.dart';
import '../../../vendeur/presentation/pages/produit_form_page.dart';

/// ─── Espace Vendeur ──────────────────────────────────────────────────────────
/// Accessible à un utilisateur dont le rôle est « Vendeur ».
/// Regroupe ses fonctionnalités supplémentaires (en plus des droits client) :
///   1. Faire une demande de publication de produit (validée par le super admin)
///      et suivre le statut d'avancement de chaque demande.
///   2. Voir ses produits publiés.
///   3. Suivre le stock disponible / réservé de chaque produit.
///
/// Données réelles : GET /vendeur/liste-produits (VendeurProduitDataSource).
/// Le statut de validation (statutValidation) et le stock proviennent du backend.

// ─── Palette (locale) ─────────────────────────────────────────────────────────
class _C {
  static const green      = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const gold       = Color(0xFFF5C518);
  static const goldDark   = Color(0xFF8A6D00);
  static const goldLight  = Color(0xFFFFF8E1);
  static const black      = Color(0xFF1A1A1A);
  static const white      = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF5F7FB);
  static const surface    = Color(0xFFF7F9FC);
  static const border     = Color(0xFFEDF0F7);
  static const sub        = Color(0xFF6B7280);
  static const label      = Color(0xFF9AA3B2);
  static const placeholder= Color(0xFFC2C9D6);
  static const green2     = Color(0xFF2E7D32);
  static const greenBg    = Color(0xFFE8F5E9);
  static const orange     = Color(0xFFFF8F00);
  static const orangeBg   = Color(0xFFFFF3E0);
  static const blue       = Color(0xFF1976D2);
  static const blueBg     = Color(0xFFE3F2FD);
  static const red        = Color(0xFFE53935);
  static const redBg      = Color(0xFFFEF3F2);
}

// ─── Métadonnées de statut de validation ──────────────────────────────────────
class _StatutMeta {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatutMeta(this.label, this.color, this.bg, this.icon);
}

/// Clés = valeurs `statutValidation` du backend.
const Map<String, _StatutMeta> _statutMeta = {
  'en_attente':   _StatutMeta('En attente', _C.orange, _C.orangeBg, Icons.hourglass_empty_rounded),
  'valide_step1': _StatutMeta('En examen', _C.blue, _C.blueBg, Icons.search_rounded),
  'valide':       _StatutMeta('Publié', _C.green, _C.greenLight, Icons.storefront_rounded),
  'rejete':       _StatutMeta('Rejetée', _C.red, _C.redBg, Icons.cancel_rounded),
};

_StatutMeta _metaFor(String statut) =>
    _statutMeta[statut] ?? _statutMeta['en_attente']!;

// ══════════════════════════════════════════════════════════════════════════════
class EspaceVendeurPage extends StatefulWidget {
  final User? user;
  const EspaceVendeurPage({super.key, this.user});

  @override
  State<EspaceVendeurPage> createState() => _EspaceVendeurPageState();
}

class _EspaceVendeurPageState extends State<EspaceVendeurPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _ds = sl<VendeurProduitDataSource>();

  List<ProduitModel> _produits = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final produits = await _ds.mesProduits();
      if (!mounted) return;
      setState(() { _produits = produits; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Chargement impossible'; _loading = false; });
    }
  }

  // ── Dérivés ──
  List<ProduitModel> get _demandes =>
      _produits.where((p) => p.statutValidation != 'valide').toList();
  List<ProduitModel> get _publies =>
      _produits.where((p) => p.statutValidation == 'valide').toList();

  int get _nbPublies => _publies.length;
  int get _nbEnAttente => _produits
      .where((p) => p.statutValidation == 'en_attente' || p.statutValidation == 'valide_step1')
      .length;
  int get _nbRupture => _publies.where((p) => p.stock <= 0).length;

  int _prix(ProduitModel p) => (num.tryParse(p.prix) ?? 0).round();

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: _C.white)),
        backgroundColor: _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _ouvrirNouvelleDemande() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProduitFormPage()),
    );
    // Au retour, on recharge la liste (une éventuelle demande a pu être créée).
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHeader()),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _tabContent(_buildDemandesTab),
                  _tabContent(_buildProduitsTab),
                  _tabContent(_buildStockTab),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tab,
        builder: (_, __) => _tab.index == 0
            ? FloatingActionButton.extended(
                onPressed: _ouvrirNouvelleDemande,
                backgroundColor: _C.green,
                icon: const Icon(Icons.add_rounded, color: _C.white),
                label: Text('Nouvelle demande',
                    style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: _C.white, fontSize: 13)),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  /// Enveloppe une vue d'onglet avec les états chargement / erreur.
  Widget _tabContent(Widget Function() builder) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.green, strokeWidth: 2.5));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: _C.sub, size: 46),
          const SizedBox(height: 10),
          Text(_error!, style: GoogleFonts.dmSans(color: _C.sub)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(12)),
              child: Text('Réessayer', style: GoogleFonts.dmSans(color: _C.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
    }
    return RefreshIndicator(color: _C.green, onRefresh: _load, child: builder());
  }

  // ── En-tête (navy) ──
  Widget _buildHeader() {
    return Container(
      color: _C.black,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.white, size: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(text: 'Espace ', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: _C.white, letterSpacing: -0.5)),
                            TextSpan(text: 'Vendeur', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: _C.gold, letterSpacing: -0.5)),
                          ]),
                        ),
                        Text(
                          widget.user != null ? '${widget.user!.prenom} ${widget.user!.nom}' : 'Vos produits & demandes',
                          style: GoogleFonts.dmSans(fontSize: 12, color: _C.label),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _C.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.gold.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.storefront_rounded, color: _C.gold, size: 12),
                      const SizedBox(width: 4),
                      Text('Vendeur', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: _C.gold)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // KPIs
              Row(
                children: [
                  Expanded(child: _kpi('$_nbPublies', 'Produits publiés', Icons.inventory_2_outlined)),
                  const SizedBox(width: 8),
                  Expanded(child: _kpi('$_nbEnAttente', 'En attente', Icons.hourglass_empty_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _kpi('$_nbRupture', 'En rupture', Icons.error_outline_rounded)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _C.gold.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.gold.withOpacity(0.25)),
                ),
                child: Row(children: [
                  const Icon(Icons.inventory_rounded, color: _C.gold, size: 18),
                  const SizedBox(width: 10),
                  Text('Produits au catalogue', style: GoogleFonts.dmSans(fontSize: 12, color: _C.label)),
                  const Spacer(),
                  Text('${_produits.length}', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800, color: _C.white)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpi(String val, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(children: [
        Icon(icon, color: _C.gold, size: 18),
        const SizedBox(height: 6),
        Text(val, style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: _C.white)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 10, color: _C.label, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── TabBar ──
  Widget _buildTabBar() {
    return Container(
      color: _C.white,
      child: TabBar(
        controller: _tab,
        labelColor: _C.green,
        unselectedLabelColor: _C.label,
        indicatorColor: _C.green,
        indicatorWeight: 2.5,
        labelStyle: GoogleFonts.sora(fontSize: 12.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.sora(fontSize: 12.5, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Demandes'),
          Tab(text: 'Mes produits'),
          Tab(text: 'Mon stock'),
        ],
      ),
    );
  }

  // ══════════════ TAB 1 — DEMANDES ══════════════
  Widget _buildDemandesTab() {
    final demandes = _demandes;
    if (demandes.isEmpty) {
      return _empty(Icons.inbox_rounded, 'Aucune demande',
          'Soumettez un produit à la validation du super admin.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: demandes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _demandeCard(demandes[i]),
    );
  }

  Widget _demandeCard(ProduitModel d) {
    final meta = _metaFor(d.statutValidation);
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: meta.bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(meta.icon, color: meta.color, size: 20),
          ),
          title: Text(d.nom, style: GoogleFonts.sora(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.black)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('${_fmt(_prix(d))} FCFA · stock ${d.stock}',
                style: GoogleFonts.dmSans(fontSize: 11.5, color: _C.sub)),
          ),
          trailing: _badge(meta),
          children: [
            if (d.description.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(d.description, style: GoogleFonts.dmSans(fontSize: 12.5, color: _C.sub, height: 1.4)),
              ),
            const SizedBox(height: 14),
            if (d.statutValidation == 'rejete')
              _rejetBox('Votre demande n\'a pas été retenue. Contactez le support pour en savoir plus.')
            else
              _timeline(d.statutValidation),
          ],
        ),
      ),
    );
  }

  Widget _badge(_StatutMeta meta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: meta.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(meta.label, style: GoogleFonts.dmSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: meta.color)),
    );
  }

  // Timeline d'avancement : Soumise → En examen → Validée → Publiée
  Widget _timeline(String statut) {
    const etapes = ['Soumise', 'En examen', 'Validée', 'Publiée'];
    const indexParStatut = {'en_attente': 0, 'valide_step1': 1, 'valide': 3};
    final courant = indexParStatut[statut] ?? 0;
    return Row(
      children: List.generate(etapes.length, (i) {
        final done = i <= courant;
        final isLast = i == etapes.length - 1;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: done ? _C.green : _C.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: done ? _C.green : _C.border, width: 1.5),
                    ),
                    child: Icon(done ? Icons.check_rounded : Icons.circle, color: done ? _C.white : _C.placeholder, size: done ? 13 : 6),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 58,
                    child: Text(etapes[i], textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(fontSize: 9.5, fontWeight: done ? FontWeight.w700 : FontWeight.w500, color: done ? _C.green : _C.label)),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: i < courant ? _C.green : _C.border,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _rejetBox(String motif) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _C.redBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.red.withOpacity(0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, color: _C.red, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(motif, style: GoogleFonts.dmSans(fontSize: 12, color: _C.red, height: 1.4, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  // ══════════════ TAB 2 — MES PRODUITS ══════════════
  Widget _buildProduitsTab() {
    final publies = _publies;
    if (publies.isEmpty) {
      return _empty(Icons.inventory_2_outlined, 'Aucun produit publié',
          'Vos produits validés apparaîtront ici.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: publies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _produitCard(publies[i]),
    );
  }

  Widget _produitCard(ProduitModel p) {
    final total = p.stock + p.stockAlloue;
    final hasImage = p.image.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: _C.greenLight,
                borderRadius: BorderRadius.circular(12),
                image: hasImage ? DecorationImage(image: NetworkImage(p.image), fit: BoxFit.cover) : null,
              ),
              child: hasImage ? null : const Icon(Icons.shopping_bag_rounded, color: _C.green, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: _C.black)),
                const SizedBox(height: 2),
                Text('${_fmt(_prix(p))} FCFA', style: GoogleFonts.dmSans(fontSize: 12, color: _C.sub, fontWeight: FontWeight.w600)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(20)),
              child: Text('Publié', style: GoogleFonts.dmSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: _C.green)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _miniStat('${p.stock}', 'En stock', Icons.inventory_outlined, _C.goldDark, _C.goldLight)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('${p.stockAlloue}', 'Réservé', Icons.lock_clock_outlined, _C.blue, _C.blueBg)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('$total', 'Total', Icons.summarize_outlined, _C.green2, _C.greenBg)),
          ]),
        ],
      ),
    );
  }

  Widget _miniStat(String val, String label, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 5),
        Text(val, style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w800, color: _C.black)),
        Text(label, style: GoogleFonts.dmSans(fontSize: 9.5, color: _C.sub)),
      ]),
    );
  }

  // ══════════════ TAB 3 — MON STOCK ══════════════
  Widget _buildStockTab() {
    final publies = _publies;
    if (publies.isEmpty) {
      return _empty(Icons.inventory_outlined, 'Aucun stock à suivre',
          'Le stock de vos produits publiés apparaîtra ici.');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Text('Stock de vos produits', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: _C.black)),
        const SizedBox(height: 4),
        Text('Suivez le stock disponible et le stock réservé aux commandes en cours.',
            style: GoogleFonts.dmSans(fontSize: 12, color: _C.sub)),
        const SizedBox(height: 14),
        ...publies.map(_stockCard),
      ],
    );
  }

  Widget _stockCard(ProduitModel p) {
    final total = p.stock + p.stockAlloue;
    final ratio = total == 0 ? 0.0 : p.stock / total;
    final faible = p.stock <= (total * 0.2);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(p.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.black))),
            if (faible)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _C.redBg, borderRadius: BorderRadius.circular(20)),
                child: Text('Stock faible', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: _C.red)),
              ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: _C.surface,
              valueColor: AlwaysStoppedAnimation(faible ? _C.red : _C.green),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('${p.stock} disponible', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: _C.black)),
            Text(' · ${p.stockAlloue} réservé', style: GoogleFonts.dmSans(fontSize: 12, color: _C.sub)),
            const Spacer(),
            GestureDetector(
              onTap: () => _snack('Réapprovisionnement bientôt disponible depuis l\'application.'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, color: _C.white, size: 15),
                  const SizedBox(width: 4),
                  Text('Réappro.', style: GoogleFonts.dmSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: _C.white)),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _empty(IconData icon, String title, String sub) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: _C.greenLight, shape: BoxShape.circle),
            child: Icon(icon, color: _C.green, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: _C.black)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(sub, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 12.5, color: _C.sub, height: 1.5)),
          ),
        ]),
      ],
    );
  }
}
