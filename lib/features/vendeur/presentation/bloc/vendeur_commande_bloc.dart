import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/vendeur_commande_model.dart';
import '../../domain/usecases/get_vendeur_tableau_bord.dart';

// ───── Events ─────
abstract class VendeurCommandeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// `statut` null = toutes les commandes.
class LoadCommandesVendeur extends VendeurCommandeEvent {
  final String? statut;
  LoadCommandesVendeur({this.statut});
  @override
  List<Object?> get props => [statut];
}

// ───── States ─────
abstract class VendeurCommandeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VendeurCommandeLoading extends VendeurCommandeState {}

class VendeurCommandeLoaded extends VendeurCommandeState {
  final List<VendeurCommandeModel> commandes;
  final String? statut;
  VendeurCommandeLoaded(this.commandes, this.statut);
  @override
  List<Object?> get props => [commandes, statut];
}

class VendeurCommandeError extends VendeurCommandeState {
  final String message;
  VendeurCommandeError(this.message);
  @override
  List<Object?> get props => [message];
}

// ───── Bloc ─────
class VendeurCommandeBloc extends Bloc<VendeurCommandeEvent, VendeurCommandeState> {
  final GetVendeurTableauBord tableauBord;

  VendeurCommandeBloc({required this.tableauBord}) : super(VendeurCommandeLoading()) {
    on<LoadCommandesVendeur>(_onLoad);
  }

  Future<void> _onLoad(
    LoadCommandesVendeur event,
    Emitter<VendeurCommandeState> emit,
  ) async {
    emit(VendeurCommandeLoading());
    final result = await tableauBord.commandes(statut: event.statut);
    result.fold(
      (failure) => emit(VendeurCommandeError(failure.errorMessage)),
      (commandes) => emit(VendeurCommandeLoaded(commandes, event.statut)),
    );
  }
}
