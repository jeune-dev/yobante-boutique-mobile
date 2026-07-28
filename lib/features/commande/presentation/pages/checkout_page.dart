import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/app_message.dart';
import '../../data/models/adresse_model.dart';
import '../../data/models/paiement_model.dart';
import '../../data/repositories/commande_repository.dart';
import '../../data/services/panier_service.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const label = Color(0xFF9AA3B2);
  static const border = Color(0xFFDDE3EF);
  static const or = Color(0xFFF5C518);
}

/// Où livrer : à une adresse déjà enregistrée, ou à une autre saisie sur place.
enum _LieuLivraison { chezMoi, ailleurs }

class CheckoutPage extends StatelessWidget {
  /// Articles cochés dans le panier. Nul : tout le panier est commandé.
  final Set<String>? produitIds;
  const CheckoutPage({super.key, this.produitIds});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommandeBloc>(),
      child: _CheckoutView(produitIds: produitIds),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  final Set<String>? produitIds;
  const _CheckoutView({this.produitIds});
  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

/// Méthodes de règlement acceptées par le backend.
const _methodes = <String, ({String libelle, IconData icone, String detail})>{
  'cash_livraison': (
    libelle: 'Paiement à la livraison',
    icone: Icons.payments_outlined,
    detail: 'Vous réglez au livreur, rien à payer maintenant',
  ),
  'wave': (
    libelle: 'Wave',
    icone: Icons.account_balance_wallet_outlined,
    detail: 'Règlement immédiat',
  ),
  'orange_money': (
    libelle: 'Orange Money',
    icone: Icons.account_balance_wallet_outlined,
    detail: 'Règlement immédiat',
  ),
  'carte': (
    libelle: 'Carte bancaire',
    icone: Icons.credit_card,
    detail: 'Règlement immédiat',
  ),
};

class _CheckoutViewState extends State<_CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();

  // Saisie de l'adresse ponctuelle (option « ailleurs »).
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _rueCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();

  String _methode = 'cash_livraison';
  _LieuLivraison _lieu = _LieuLivraison.chezMoi;
  DateTime? _dateSouhaitee;

  /// Création de l'adresse ponctuelle avant la commande : évite un double envoi
  /// si l'utilisateur reste sur la page après une erreur.
  bool _envoiEnCours = false;

  List<AdresseModel> _adresses = const [];
  String? _adresseId;
  bool _chargementAdresses = true;
  String? _erreurAdresses;

  final _panier = sl<PanierService>();

  bool get _paiementALaLivraison => _methode == 'cash_livraison';

  double get _totalArticles => widget.produitIds != null
      ? _panier.totalSelection(widget.produitIds!)
      : _panier.total;

  @override
  void initState() {
    super.initState();
    _chargerAdresses();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _rueCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerAdresses() async {
    setState(() {
      _chargementAdresses = true;
      _erreurAdresses = null;
    });
    try {
      final adresses = await sl<CommandeRepository>().adresses();
      if (!mounted) return;
      setState(() {
        _adresses = adresses;
        _adresseId = adresses.isEmpty
            ? null
            : adresses
                .firstWhere((a) => a.parDefaut, orElse: () => adresses.first)
                .id;
        // Sans adresse enregistrée, « chez moi » n'a rien à désigner : on
        // ouvre directement la saisie.
        if (adresses.isEmpty) _lieu = _LieuLivraison.ailleurs;
        _chargementAdresses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargementAdresses = false;
        _erreurAdresses = e.toString();
      });
    }
  }

  Future<void> _choisirDate() async {
    final aujourdhui = DateTime.now();
    final choix = await showDatePicker(
      context: context,
      initialDate: _dateSouhaitee ?? aujourdhui.add(const Duration(days: 1)),
      firstDate: aujourdhui,
      lastDate: aujourdhui.add(const Duration(days: 90)),
      helpText: 'Quand souhaitez-vous être livré ?',
      locale: const Locale('fr', 'FR'),
    );
    if (choix != null) setState(() => _dateSouhaitee = choix);
  }

  /// Valide la saisie, crée l'adresse si besoin, puis lance la commande.
  Future<void> _soumettre() async {
    if (_envoiEnCours) return;
    if (!_formKey.currentState!.validate()) return;

    String? adresseId = _adresseId;

    if (_lieu == _LieuLivraison.ailleurs) {
      setState(() => _envoiEnCours = true);
      try {
        final adresse = await sl<CommandeRepository>().creerAdresse(
          nomComplet: _nomCtrl.text.trim(),
          telephone: _telCtrl.text.trim(),
          rue: _rueCtrl.text.trim(),
          ville: _villeCtrl.text.trim(),
        );
        adresseId = adresse.id;
      } catch (e) {
        if (!mounted) return;
        setState(() => _envoiEnCours = false);
        AppMessage.error(context, "Adresse refusée : ${_lisible(e)}");
        return;
      }
      if (!mounted) return;
      setState(() => _envoiEnCours = false);
    }

    if (adresseId == null || adresseId.isEmpty) {
      AppMessage.error(context, 'Choisissez où vous souhaitez être livré');
      return;
    }

    if (!mounted) return;
    context.read<CommandeBloc>().add(CreerCommande(
          adresseId: adresseId,
          methode: _methode,
          produitIds: widget.produitIds,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          dateLivraisonSouhaitee: _dateSouhaitee,
        ));
  }

  String _lisible(Object e) {
    final texte = e.toString();
    return texte.length > 120 ? '${texte.substring(0, 120)}…' : texte;
  }

  /// Ouvre la page du fournisseur. Au retour, c'est le serveur qui fait foi.
  Future<void> _ouvrirPaiement(PaiementModel paiement) async {
    final uri = Uri.tryParse(paiement.urlPaiement ?? '');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: const Text('Validation de la commande'),
      ),
      body: BlocConsumer<CommandeBloc, CommandeState>(
        listener: (context, state) async {
          if (state is CommandeError) {
            AppMessage.error(context, state.message);
          } else if (state is CommandeCreee) {
            await _viderPanier();
            if (!context.mounted) return;

            // Paiement à la livraison : la commande suffit, on n'impose aucun
            // règlement. Le paiement est déjà enregistré côté serveur, en
            // attente, avec la méthode choisie.
            if (_paiementALaLivraison) {
              AppMessage.success(
                context,
                'Commande enregistrée — vous réglerez à la livraison.',
              );
              _allerMesCommandes(context);
              return;
            }
            context.read<CommandeBloc>().add(PayerCommande(state.commande.id));
          } else if (state is PaiementInitie) {
            if (state.paiement.demandeUneAction && context.mounted) {
              await _ouvrirPaiement(state.paiement);
            }
            if (context.mounted) {
              AppMessage.success(
                context,
                'Finalisez le paiement puis revenez : le statut se met à jour ici.',
              );
              _allerMesCommandes(context);
            }
          }
        },
        builder: (context, state) {
          final loading = state is CommandeLoading || _envoiEnCours;
          return AbsorbPointer(
            absorbing: loading,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _section('Où souhaitez-vous être livré ?'),
                  _choixLieu(),
                  const SizedBox(height: 12),
                  if (_lieu == _LieuLivraison.chezMoi)
                    _selecteurAdresse()
                  else
                    _formulaireAdresse(),
                  const SizedBox(height: 22),
                  _section('Date de livraison souhaitée'),
                  _selecteurDate(),
                  const SizedBox(height: 22),
                  _section('Mode de règlement'),
                  _selecteurMethode(),
                  const SizedBox(height: 22),
                  _section('Note (optionnel)'),
                  _input(_noteCtrl, 'Une précision pour la livraison ?',
                      maxLines: 3),
                  const SizedBox(height: 22),
                  _recapitulatif(),
                  const SizedBox(height: 20),
                  _boutonConfirmer(loading),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Choix du lieu ──────────────────────────────────────────────────────────
  Widget _choixLieu() {
    return Row(
      children: [
        Expanded(
          child: _carteChoix(
            actif: _lieu == _LieuLivraison.chezMoi,
            icone: Icons.home_outlined,
            titre: 'Chez moi',
            detail: 'À mon adresse enregistrée',
            onTap: _adresses.isEmpty
                ? null
                : () => setState(() => _lieu = _LieuLivraison.chezMoi),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _carteChoix(
            actif: _lieu == _LieuLivraison.ailleurs,
            icone: Icons.place_outlined,
            titre: 'Autre part',
            detail: 'Je saisis une adresse',
            onTap: () => setState(() => _lieu = _LieuLivraison.ailleurs),
          ),
        ),
      ],
    );
  }

  Widget _carteChoix({
    required bool actif,
    required IconData icone,
    required String titre,
    required String detail,
    VoidCallback? onTap,
  }) {
    final desactive = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: actif ? _C.greenLight : _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: actif ? _C.green : _C.border, width: actif ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone,
                size: 22, color: desactive ? _C.border : (actif ? _C.green : _C.sub)),
            const SizedBox(height: 8),
            Text(
              titre,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: desactive ? _C.label : _C.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desactive ? 'Aucune adresse enregistrée' : detail,
              style: const TextStyle(fontSize: 11.5, color: _C.sub, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  // ── Adresses enregistrées ──────────────────────────────────────────────────
  Widget _selecteurAdresse() {
    if (_chargementAdresses) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_erreurAdresses != null) {
      return Row(
        children: [
          const Expanded(
            child: Text('Adresses indisponibles',
                style: TextStyle(color: _C.sub, fontSize: 13)),
          ),
          TextButton(onPressed: _chargerAdresses, child: const Text('Réessayer')),
        ],
      );
    }
    return Column(
      children: [
        for (final adresse in _adresses)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _adresseId = adresse.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _adresseId == adresse.id ? _C.greenLight : _C.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _adresseId == adresse.id ? _C.green : _C.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _adresseId == adresse.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 19,
                      color: _adresseId == adresse.id ? _C.green : _C.border,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adresse.nomComplet,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: _C.black),
                          ),
                          Text(adresse.resume,
                              style: const TextStyle(fontSize: 12, color: _C.sub)),
                          if (adresse.telephone.isNotEmpty)
                            Text(adresse.telephone,
                                style:
                                    const TextStyle(fontSize: 12, color: _C.label)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Adresse ponctuelle ─────────────────────────────────────────────────────
  Widget _formulaireAdresse() {
    String? obligatoire(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

    return Column(
      children: [
        _input(_nomCtrl, 'Nom et prénom du destinataire',
            validator: obligatoire),
        const SizedBox(height: 10),
        _input(_telCtrl, 'Numéro de téléphone',
            keyboard: TextInputType.phone, validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Champ requis';
          if (v.trim().replaceAll(RegExp(r'\D'), '').length < 9) {
            return 'Numéro trop court';
          }
          return null;
        }),
        const SizedBox(height: 10),
        _input(_rueCtrl, 'Quartier, rue, point de repère',
            validator: obligatoire),
        const SizedBox(height: 10),
        _input(_villeCtrl, 'Ville', validator: obligatoire),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: _C.label),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Cette adresse est ajoutée à votre carnet pour vos prochaines commandes.',
                style: TextStyle(fontSize: 11.5, color: _C.label, height: 1.3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Date souhaitée ─────────────────────────────────────────────────────────
  Widget _selecteurDate() {
    final texte = _dateSouhaitee == null
        ? 'Au plus tôt (aucune préférence)'
        : DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_dateSouhaitee!);

    return InkWell(
      onTap: _choisirDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, size: 20, color: _C.green),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                texte,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _dateSouhaitee == null ? _C.sub : _C.black,
                ),
              ),
            ),
            if (_dateSouhaitee != null)
              GestureDetector(
                onTap: () => setState(() => _dateSouhaitee = null),
                child: const Icon(Icons.close_rounded, size: 18, color: _C.label),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: _C.label),
          ],
        ),
      ),
    );
  }

  // ── Mode de règlement ──────────────────────────────────────────────────────
  Widget _selecteurMethode() {
    return Column(
      children: [
        for (final entree in _methodes.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _methode = entree.key),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _methode == entree.key ? _C.greenLight : _C.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _methode == entree.key ? _C.green : _C.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _methode == entree.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 19,
                      color: _methode == entree.key ? _C.green : _C.border,
                    ),
                    const SizedBox(width: 11),
                    Icon(entree.value.icone, size: 19, color: _C.sub),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entree.value.libelle,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _C.black)),
                          Text(entree.value.detail,
                              style: const TextStyle(
                                  fontSize: 11.5, color: _C.sub)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Récapitulatif ──────────────────────────────────────────────────────────
  Widget _recapitulatif() {
    Widget ligne(String gauche, String droite, {bool fort = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(gauche,
                  style: TextStyle(
                      color: fort ? _C.black : _C.sub,
                      fontWeight: fort ? FontWeight.w800 : FontWeight.w500,
                      fontSize: fort ? 14.5 : 13)),
              Text(droite,
                  style: TextStyle(
                      color: fort ? _C.green : _C.black,
                      fontWeight: fort ? FontWeight.w800 : FontWeight.w600,
                      fontSize: fort ? 15 : 13)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          ligne('Articles', '${_totalArticles.toStringAsFixed(0)} FCFA'),
          // Les frais dépendent de la ville de livraison : c'est le serveur qui
          // les calcule, on ne les invente pas ici.
          ligne('Livraison', 'calculés à la validation'),
          const Divider(height: 18, color: _C.border),
          ligne('À payer', '${_totalArticles.toStringAsFixed(0)} FCFA + livraison',
              fort: true),
          if (_paiementALaLivraison) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: _C.or.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 17, color: _C.black),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rien à payer maintenant : vous réglerez au livreur.',
                      style: TextStyle(fontSize: 12, color: _C.black, height: 1.3),
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

  Widget _boutonConfirmer(bool loading) {
    return ElevatedButton(
      onPressed: loading ? null : _soumettre,
      style: ElevatedButton.styleFrom(
        backgroundColor: _C.green,
        foregroundColor: _C.white,
        disabledBackgroundColor: _C.border,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Text(
              _paiementALaLivraison
                  ? 'Confirmer ma commande'
                  : 'Confirmer et payer',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
    );
  }

  /// Retire du panier ce qui vient d'être commandé : les articles non cochés
  /// y restent pour une commande suivante.
  Future<void> _viderPanier() async {
    if (widget.produitIds != null) {
      await _panier.retirerSelection(widget.produitIds!);
    } else {
      await _panier.vider();
    }
  }

  void _allerMesCommandes(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.mesCommandesRoute,
      (route) => route.isFirst,
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: _C.black, fontSize: 15)),
      );

  Widget _input(TextEditingController c, String hint,
      {TextInputType? keyboard,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13.5, color: _C.label),
        filled: true,
        fillColor: _C.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.green),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
      ),
    );
  }
}
