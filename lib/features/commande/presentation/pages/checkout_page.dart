import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../data/models/adresse_model.dart';
import '../../data/models/paiement_model.dart';
import '../../data/repositories/commande_repository.dart';
import '../../data/services/panier_service.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';

class _C {
  static const green = Color(0xFF163A9E);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const border = Color(0xFFDDE3EF);
}

class CheckoutPage extends StatelessWidget {
  /// Si non-null : on ne commande que les articles de cette boutique.
  final String? vendeurId;
  const CheckoutPage({super.key, this.vendeurId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommandeBloc>(),
      child: _CheckoutView(vendeurId: vendeurId),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  final String? vendeurId;
  const _CheckoutView({this.vendeurId});
  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

/// Méthodes de règlement acceptées par le backend.
const _methodes = <String, String>{
  'wave': 'Wave',
  'orange_money': 'Orange Money',
  'carte': 'Carte bancaire',
  'cash_livraison': 'À la livraison',
};

class _CheckoutViewState extends State<_CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();

  String _methode = 'cash_livraison';

  /// La commande référence une adresse enregistrée : on charge celles du
  /// compte plutôt que de faire saisir du texte libre.
  List<AdresseModel> _adresses = const [];
  String? _adresseId;
  bool _chargementAdresses = true;
  String? _erreurAdresses;

  final _panier = sl<PanierService>();

  @override
  void initState() {
    super.initState();
    _chargerAdresses();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
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
        _adresseId = adresses
            .firstWhere(
              (a) => a.parDefaut,
              orElse: () => adresses.isNotEmpty
                  ? adresses.first
                  : const AdresseModel(
                      id: '', nomComplet: '', telephone: '', rue: '', ville: '', pays: ''),
            )
            .id;
        if (_adresseId!.isEmpty) _adresseId = null;
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

  void _soumettre(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (_adresseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez une adresse de livraison depuis votre profil'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    context.read<CommandeBloc>().add(CreerCommande(
          adresseId: _adresseId!,
          methode: _methode,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        ));
  }

  /// Ouvre la page du fournisseur. Au retour, on interroge le serveur : le
  /// résultat du paiement ne transite jamais par le client.
  Future<void> _ouvrirPaiement(BuildContext context, PaiementModel paiement) async {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is CommandeCreee) {
            // La commande existe : on enchaîne sur le règlement, quel que soit
            // le mode. C'est le serveur qui sait s'il y a une page à ouvrir.
            context.read<CommandeBloc>().add(PayerCommande(state.commande.id));
          } else if (state is PaiementInitie) {
            await _viderPanier();
            if (state.paiement.demandeUneAction && context.mounted) {
              await _ouvrirPaiement(context, state.paiement);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.paiement.demandeUneAction
                        ? 'Finalisez le paiement puis revenez : le statut se met à jour ici.'
                        : 'Commande confirmée — réglez à la livraison.',
                  ),
                ),
              );
              _allerMesCommandes(context);
            }
          }
        },
        builder: (context, state) {
          final loading = state is CommandeLoading;
          return AbsorbPointer(
            absorbing: loading,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section('Adresse de livraison'),
                  _selecteurAdresse(),
                  const SizedBox(height: 20),
                  _section('Mode de règlement'),
                  _selecteurMethode(),
                  const SizedBox(height: 20),
                  _section('Note (optionnel)'),
                  _input(_noteCtrl, 'Une précision pour le vendeur ?',
                      maxLines: 3),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loading ? null : () => _soumettre(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.green,
                      foregroundColor: _C.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            'Confirmer (${(widget.vendeurId != null ? _panier.totalVendeur(widget.vendeurId!) : _panier.total).toStringAsFixed(0)} FCFA + livraison)',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Vide le panier après commande : uniquement la boutique concernée en mode
  /// par-boutique, sinon le panier entier.
  Future<void> _viderPanier() async {
    if (widget.vendeurId != null) {
      await _panier.viderVendeur(widget.vendeurId!);
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
    if (_adresses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: const Text(
          "Aucune adresse enregistrée. Ajoutez-en une depuis votre profil pour "
          'pouvoir être livré.',
          style: TextStyle(fontSize: 13, color: _C.sub, height: 1.4),
        ),
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
                  color: _adresseId == adresse.id
                      ? _C.green.withValues(alpha: 0.08)
                      : _C.white,
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
                                fontWeight: FontWeight.w700, fontSize: 13.5, color: _C.black),
                          ),
                          Text(
                            adresse.resume,
                            style: const TextStyle(fontSize: 12, color: _C.sub),
                          ),
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
                  color: _methode == entree.key
                      ? _C.green.withValues(alpha: 0.08)
                      : _C.white,
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
                    Text(
                      entree.value,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600, color: _C.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
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
