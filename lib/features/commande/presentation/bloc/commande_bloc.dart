import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/panier_item.dart';
import '../../data/services/panier_service.dart';
import '../../../../injection_container.dart';
import '../../data/repositories/commande_repository.dart';
import 'commande_event.dart';
import 'commande_state.dart';

class CommandeBloc extends Bloc<CommandeEvent, CommandeState> {
  final CommandeRepository repository;

  CommandeBloc(this.repository) : super(CommandeInitial()) {
    on<LoadMesCommandes>(_onLoadMesCommandes);
    on<CreerCommande>(_onCreerCommande);
    on<PayerCommande>(_onPayerCommande);
    on<VerifierPaiement>(_onVerifierPaiement);
    on<AnnulerCommande>(_onAnnulerCommande);
  }

  // Extrait un message d'erreur lisible (priorité au message du backend)
  String _msg(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return e.message ?? 'Erreur réseau';
    }
    return e.toString();
  }

  Future<void> _onLoadMesCommandes(
      LoadMesCommandes event, Emitter<CommandeState> emit) async {
    emit(CommandeLoading());
    try {
      final list = await repository.mesCommandes(statut: event.statut);
      emit(CommandesLoaded(list));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }

  Future<void> _onCreerCommande(
      CreerCommande event, Emitter<CommandeState> emit) async {
    emit(CommandeLoading());
    try {
      final panier = sl<PanierService>();

      // Si vendeurId est spécifié, prendre seulement ses articles ; sinon tous
      final List<PanierItem> items;
      if (event.vendeurId != null) {
        items = panier.parVendeur[event.vendeurId!] ?? [];
      } else {
        // Tous les articles de tous les vendeurs
        items = panier.parVendeur.values.expand((e) => e).toList();
      }

      // Convertir les items en format attendu par le backend
      final itemsData = items
          .map((item) => {'produitId': item.produitId, 'quantite': item.quantite})
          .toList();

      final commande = await repository.creerCommande(
        adresseId: event.adresseId,
        methode: event.methode,
        items: itemsData,
        note: event.note,
      );
      emit(CommandeCreee(commande));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }

  Future<void> _onPayerCommande(
      PayerCommande event, Emitter<CommandeState> emit) async {
    emit(CommandeLoading());
    try {
      final paiement = await repository.payer(event.commandeId);
      emit(PaiementInitie(event.commandeId, paiement));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }

  Future<void> _onVerifierPaiement(
      VerifierPaiement event, Emitter<CommandeState> emit) async {
    try {
      final paiement = await repository.statutPaiement(event.commandeId);
      emit(PaiementStatut(paiement));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }

  Future<void> _onAnnulerCommande(
      AnnulerCommande event, Emitter<CommandeState> emit) async {
    emit(CommandeLoading());
    try {
      final commande = await repository.annuler(event.commandeId);
      emit(CommandeMiseAJour(commande));
    } catch (e) {
      emit(CommandeError(_msg(e)));
    }
  }
}
