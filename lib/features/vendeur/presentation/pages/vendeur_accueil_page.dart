import 'package:flutter/material.dart';

import '../../../../injection_container.dart';
import '../../../auth/domain/entities/user.dart';
import '../../data/models/vendeur_ventes_model.dart';
import '../../domain/usecases/get_vendeur_tableau_bord.dart';
import '../widgets/entete_vendeur.dart';
import '../widgets/statut_chip.dart';

/// Accueil vendeur : vision synthétique des ventes et de l'état du catalogue.
///
/// Les ventes proviennent de `GET /vendeur/commandes/ventes`, les compteurs
/// catalogue de `GET /vendeur/produits/stats`. Les deux appels sont
/// indépendants : si l'un échoue, l'autre reste affiché.
class VendeurAccueilPage extends StatefulWidget {
  final User? user;
  const VendeurAccueilPage({super.key, this.user});

  @override
  State<VendeurAccueilPage> createState() => _VendeurAccueilPageState();
}

class _VendeurAccueilPageState extends State<VendeurAccueilPage> {
  final _tableauBord = sl<GetVendeurTableauBord>();

  VendeurVentesModel _ventes = VendeurVentesModel.vide;
  Map<String, dynamic> _stats = const {};
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

    final resultats = await Future.wait([
      _tableauBord.ventes(),
      _tableauBord.statsProduits(),
    ]);
    if (!mounted) return;

    String? erreur;
    resultats[0].fold(
      (f) => erreur = f.errorMessage,
      (v) => _ventes = v as VendeurVentesModel,
    );
    resultats[1].fold(
      (f) => erreur ??= f.errorMessage,
      (s) => _stats = s as Map<String, dynamic>,
    );

    setState(() {
      _chargement = false;
      _erreur = erreur;
    });
  }

  int _stat(String cle) => (_stats[cle] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendeurCouleurs.fond,
      body: Column(
        children: [
          EnteteVendeur(user: widget.user),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  if (_chargement)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    if (_erreur != null) _bandeauErreur(_erreur!),
                    _carteChiffreAffaires(),
                    const SizedBox(height: 14),
                    _tuilesVentes(),
                    const SizedBox(height: 22),
                    _titre('Ventes des ${_ventes.periode.jours} derniers jours'),
                    const SizedBox(height: 12),
                    _graphique(),
                    const SizedBox(height: 22),
                    _titre('Meilleures ventes'),
                    const SizedBox(height: 12),
                    _topProduits(),
                    const SizedBox(height: 22),
                    _titre('Mon catalogue'),
                    const SizedBox(height: 12),
                    _catalogue(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bandeauErreur(String message) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VendeurCouleurs.rouge.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VendeurCouleurs.rouge.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: VendeurCouleurs.rouge, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12.5, color: VendeurCouleurs.rouge),
              ),
            ),
            TextButton(onPressed: _charger, child: const Text('Réessayer')),
          ],
        ),
      );

  Widget _titre(String texte) => Text(
        texte,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: VendeurCouleurs.noir,
        ),
      );

  // ── Chiffre d'affaires ────────────────────────────────────────────────
  Widget _carteChiffreAffaires() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VendeurCouleurs.bleu, Color(0xFF2A55C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Chiffre d\'affaires total',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const Spacer(),
              if (_ventes.commandesATraiter > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: VendeurCouleurs.or,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_ventes.commandesATraiter} à traiter',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: VendeurCouleurs.noir,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatFcfa(_ventes.chiffreAffaires),
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'dont ${formatFcfa(_ventes.periode.chiffreAffaires)} sur ${_ventes.periode.jours} jours',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _tuilesVentes() {
    return Row(
      children: [
        Expanded(
          child: _tuile(
            Icons.receipt_long_rounded,
            '${_ventes.nombreCommandes}',
            'Commandes',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _tuile(
            Icons.inventory_2_rounded,
            '${_ventes.unitesVendues}',
            'Articles vendus',
          ),
        ),
      ],
    );
  }

  Widget _tuile(IconData icone, String valeur, String libelle) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VendeurCouleurs.blanc,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VendeurCouleurs.bordure),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 19, color: VendeurCouleurs.bleu),
            const SizedBox(height: 10),
            Text(
              valeur,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: VendeurCouleurs.noir,
              ),
            ),
            Text(
              libelle,
              style: const TextStyle(fontSize: 12, color: VendeurCouleurs.gris),
            ),
          ],
        ),
      );

  // ── Graphique ─────────────────────────────────────────────────────────
  /// Histogramme simple du CA par jour. Volontairement sans dépendance de
  /// charting : quelques barres proportionnelles suffisent ici.
  Widget _graphique() {
    if (_ventes.parJour.isEmpty) {
      return _carteVide('Aucune vente sur la période');
    }

    final maxCa = _ventes.parJour
        .map((j) => j.chiffreAffaires)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      decoration: BoxDecoration(
        color: VendeurCouleurs.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendeurCouleurs.bordure),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final jour in _ventes.parJour)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      // maxCa > 0 garanti : parJour ne contient que des ventes.
                      height: (jour.chiffreAffaires / maxCa) * 96 + 4,
                      decoration: BoxDecoration(
                        color: VendeurCouleurs.bleu,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _jourCourt(jour.jour),
                      style: const TextStyle(
                        fontSize: 9,
                        color: VendeurCouleurs.gris,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// `2026-07-18` → `18/07`
  String _jourCourt(String iso) {
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    return '${parts[2].substring(0, 2)}/${parts[1]}';
  }

  // ── Top produits ──────────────────────────────────────────────────────
  Widget _topProduits() {
    if (_ventes.topProduits.isEmpty) {
      return _carteVide('Pas encore de vente enregistrée');
    }
    return Container(
      decoration: BoxDecoration(
        color: VendeurCouleurs.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendeurCouleurs.bordure),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _ventes.topProduits.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 14, endIndent: 14, color: VendeurCouleurs.bordure),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: VendeurCouleurs.bleuClair,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: VendeurCouleurs.bleu,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _ventes.topProduits[i].nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: VendeurCouleurs.noir,
                          ),
                        ),
                        Text(
                          '${_ventes.topProduits[i].unites} vendus',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: VendeurCouleurs.gris,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatFcfa(_ventes.topProduits[i].chiffreAffaires),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: VendeurCouleurs.bleu,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Catalogue ─────────────────────────────────────────────────────────
  Widget _catalogue() {
    return Row(
      children: [
        Expanded(child: _pastilleCatalogue('${_stat('valides')}', 'Publiés', VendeurCouleurs.vert)),
        const SizedBox(width: 10),
        Expanded(
          child: _pastilleCatalogue('${_stat('enAttente')}', 'En attente', VendeurCouleurs.orange),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _pastilleCatalogue('${_stat('ruptureStock')}', 'Ruptures', VendeurCouleurs.rouge),
        ),
      ],
    );
  }

  Widget _pastilleCatalogue(String valeur, String libelle, Color couleur) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: VendeurCouleurs.blanc,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VendeurCouleurs.bordure),
        ),
        child: Column(
          children: [
            Text(
              valeur,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: couleur,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              libelle,
              style: const TextStyle(fontSize: 11.5, color: VendeurCouleurs.gris),
            ),
          ],
        ),
      );

  Widget _carteVide(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: VendeurCouleurs.blanc,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VendeurCouleurs.bordure),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: VendeurCouleurs.gris),
        ),
      );
}
