import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/app_message.dart';
import '../../data/models/commande_model.dart';
import '../bloc/commande_bloc.dart';
import '../bloc/commande_event.dart';
import '../bloc/commande_state.dart';
import '../widgets/commande_card.dart' show couleurStatutCommande;

/// Argument de navigation pour la page détail.
class CommandeDetailArgs {
  final CommandeModel commande;
  final bool isVendeur;
  const CommandeDetailArgs(this.commande, {this.isVendeur = false});
}

class _C {
  static const green = Color(0xFF163A9E);
  static const greenLight = Color(0xFFEAEEF9);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF5F7FB);
  static const sub = Color(0xFF6B7280);
  static const label = Color(0xFF9AA3B2);
  static const border = Color(0xFFDDE3EF);
}

class CommandeDetailPage extends StatelessWidget {
  const CommandeDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as CommandeDetailArgs;
    return BlocProvider(
      create: (_) => sl<CommandeBloc>(),
      child: _DetailView(args: args),
    );
  }
}

class _DetailView extends StatefulWidget {
  final CommandeDetailArgs args;
  const _DetailView({required this.args});
  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  late CommandeModel commande = widget.args.commande;
  bool get isVendeur => widget.args.isVendeur;

  Timer? _rafraichissement;

  /// Un règlement déjà lancé ne doit pas repartir sur un second appui : le
  /// bouton restait actif pendant la requête et déclenchait deux paiements.
  bool _paiementEnCours = false;

  @override
  void initState() {
    super.initState();

    // La commande vient de la liste, qui n'embarque ni l'adresse ni le
    // règlement : on va chercher la fiche complète tout de suite, sinon ces
    // deux blocs restent vides jusqu'au premier rafraîchissement.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recharger());

    // Le suivi est piloté par l'administration : on redemande la commande
    // régulièrement pour refléter l'avancement sans action du client.
    // Le contexte est ici sous le BlocProvider — le lire au niveau de la page
    // levait « Could not find the correct Provider<CommandeBloc> ».
    _rafraichissement = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _recharger(),
    );
  }

  @override
  void dispose() {
    _rafraichissement?.cancel();
    super.dispose();
  }

  void _recharger() {
    if (!mounted || commande.id.isEmpty) return;
    context.read<CommandeBloc>().add(RechargerCommande(commande.id));
  }

  void _payer() {
    if (_paiementEnCours) return;
    setState(() => _paiementEnCours = true);
    context.read<CommandeBloc>().add(PayerCommande(commande.id));
  }

  void _annuler() {
    context.read<CommandeBloc>().add(AnnulerCommande(commande.id));
  }

  @override
  Widget build(BuildContext context) {
    final couleur = couleurStatutCommande(commande.statut);
    final annulable = !isVendeur && commande.statut == 'en_attente';
    // Rien à régler dans l'application quand le client paie au livreur.
    final payable = !isVendeur && commande.resteAPayer;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0.5,
        foregroundColor: _C.black,
        title: Text(
          commande.reference.isEmpty ? 'Commande' : commande.reference,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: BlocConsumer<CommandeBloc, CommandeState>(
        listener: (context, state) async {
          if (state is CommandeError) {
            setState(() => _paiementEnCours = false);
            AppMessage.error(context, state.message);
          } else if (state is CommandeMiseAJour) {
            setState(() {
              commande = state.commande;
              _paiementEnCours = false;
            });
          } else if (state is PaiementInitie) {
            setState(() => _paiementEnCours = false);
            final url = state.paiement.urlPaiement;
            if (url != null && url.isNotEmpty) {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              // Au retour du fournisseur, c'est le serveur qui fait foi.
              if (context.mounted) _recharger();
            }
          }
        },
        builder: (context, state) {
          final loading = state is CommandeLoading;
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _bandeauStatut(couleur),
                  if (commande.statut == 'rejetee' &&
                      (commande.motifRejet ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _motifRejet(),
                  ],
                  if (commande.statut != 'annulee' &&
                      commande.statut != 'rejetee') ...[
                    const SizedBox(height: 14),
                    _carte('Suivi', _timeline()),
                  ],
                  const SizedBox(height: 12),
                  _carte('Livraison', _livraison()),
                  const SizedBox(height: 12),
                  _carte('Articles (${commande.nombreArticles})', _articles()),
                  const SizedBox(height: 12),
                  _carte('Récapitulatif', _recap()),
                  const SizedBox(height: 12),
                  _carte('Règlement', _reglement()),
                  if ((commande.note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _carte('Votre note', Text(commande.note!,
                        style: const TextStyle(color: _C.sub, height: 1.5))),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
              if (loading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x22000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: _actions(payable: payable, annulable: annulable),
    );
  }

  // ── Bandeau de statut ──────────────────────────────────────────────────────
  Widget _bandeauStatut(Color couleur) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: couleur),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kStatutCommandeLabels[commande.statut] ?? commande.statut,
                  style:
                      TextStyle(color: couleur, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                if (commande.createdAt != null)
                  Text(
                    'Commandée le ${DateFormat('d MMMM yyyy à HH:mm', 'fr_FR').format(commande.createdAt!)}',
                    style: const TextStyle(color: _C.sub, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _motifRejet() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text('Motif du rejet',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.red.shade700,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Text(commande.motifRejet!,
              style: TextStyle(
                  color: Colors.red.shade900, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  // ── Suivi ──────────────────────────────────────────────────────────────────
  Widget _timeline() {
    final idx = kSuiviCommande.indexOf(commande.statut);
    return Column(
      children: List.generate(kSuiviCommande.length, (i) {
        final fait = idx >= 0 && i <= idx;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: fait ? _C.green : _C.bg,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: fait ? _C.green : _C.border, width: 2),
                  ),
                  child: fait
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
                if (i < kSuiviCommande.length - 1)
                  Container(
                      width: 2, height: 22, color: fait ? _C.green : _C.border),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                kStatutCommandeLabels[kSuiviCommande[i]] ?? kSuiviCommande[i],
                style: TextStyle(
                    color: fait ? _C.black : _C.sub,
                    fontWeight: fait ? FontWeight.w700 : FontWeight.w400),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Livraison ──────────────────────────────────────────────────────────────
  Widget _livraison() {
    final adresse = commande.adresse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (adresse == null)
          const Text('Adresse non communiquée',
              style: TextStyle(color: _C.sub, fontSize: 13))
        else ...[
          _info('Destinataire', adresse.nomComplet),
          if (adresse.telephone.isNotEmpty)
            _info('Téléphone', adresse.telephone, action: () => _appeler(adresse.telephone)),
          _info('Adresse', adresse.adresseComplete),
        ],
        _info(
          'Livraison souhaitée',
          commande.dateLivraisonSouhaitee == null
              ? 'Au plus tôt'
              : DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                  .format(commande.dateLivraisonSouhaitee!),
        ),
        _info('Frais de livraison',
            '${commande.fraisLivraison.toStringAsFixed(0)} FCFA'),
      ],
    );
  }

  Future<void> _appeler(String numero) async {
    final uri = Uri.parse('tel:$numero');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Articles ───────────────────────────────────────────────────────────────
  Widget _articles() {
    if (commande.lignes.isEmpty) {
      return const Text('Aucun article', style: TextStyle(color: _C.sub));
    }
    return Column(
      children: commande.lignes.map((l) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.nomProduit,
                        style: const TextStyle(
                            color: _C.black, fontWeight: FontWeight.w600)),
                    Text(
                      '${l.quantite} × ${l.prixUnitaire.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(color: _C.sub, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text('${l.sousTotal.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Récapitulatif ──────────────────────────────────────────────────────────
  Widget _recap() {
    Widget ligne(String l, String v, {bool fort = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l, style: const TextStyle(color: _C.sub)),
              Text(v,
                  style: TextStyle(
                      fontWeight: fort ? FontWeight.w800 : FontWeight.w600,
                      fontSize: fort ? 16 : 14,
                      color: fort ? _C.green : _C.black)),
            ],
          ),
        );
    return Column(
      children: [
        ligne('Articles', '${commande.montantProduits.toStringAsFixed(0)} FCFA'),
        ligne('Livraison', '${commande.fraisLivraison.toStringAsFixed(0)} FCFA'),
        const Divider(color: _C.border),
        ligne('Total', '${commande.montantTotal.toStringAsFixed(0)} FCFA',
            fort: true),
      ],
    );
  }

  // ── Règlement ──────────────────────────────────────────────────────────────
  Widget _reglement() {
    final paiement = commande.paiement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _info('Mode', paiement?.methodeLibelle ?? 'À la livraison'),
        _info('État', paiement?.statutLibelle ?? 'En attente'),
        if (paiement?.payeAt != null)
          _info('Réglée le',
              DateFormat('d MMMM yyyy à HH:mm', 'fr_FR').format(paiement!.payeAt!)),
        if (commande.paiementALaLivraison) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _C.greenLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 17, color: _C.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous réglerez directement au livreur : rien à payer ici.',
                    style: TextStyle(fontSize: 12, color: _C.black, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Widget? _actions({required bool payable, required bool annulable}) {
    final boutons = <Widget>[];

    if (payable) {
      boutons.add(Expanded(
        child: ElevatedButton(
          onPressed: _paiementEnCours ? null : _payer,
          style: ElevatedButton.styleFrom(
              backgroundColor: _C.green,
              foregroundColor: _C.white,
              disabledBackgroundColor: _C.border,
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Payer maintenant'),
        ),
      ));
    }
    if (annulable) {
      boutons.add(Expanded(
        child: OutlinedButton(
          onPressed: _annuler,
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Annuler la commande'),
        ),
      ));
    }

    if (boutons.isEmpty) return null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: _C.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (int i = 0; i < boutons.length; i++) ...[
              boutons[i],
              if (i < boutons.length - 1) const SizedBox(width: 12),
            ]
          ],
        ),
      ),
    );
  }

  Widget _info(String l, String v, {VoidCallback? action}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120,
                child: Text(l,
                    style: const TextStyle(color: _C.label, fontSize: 12.5))),
            Expanded(
              child: action == null
                  ? Text(v,
                      style: const TextStyle(
                          color: _C.black,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600))
                  : GestureDetector(
                      onTap: action,
                      child: Text(v,
                          style: const TextStyle(
                              color: _C.green,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700)),
                    ),
            ),
          ],
        ),
      );

  Widget _carte(String titre, Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: _C.black, fontSize: 15)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
