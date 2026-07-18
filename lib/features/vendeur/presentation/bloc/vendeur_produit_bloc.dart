import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/data/models/produit_model.dart';
import '../../domain/usecases/get_mes_produits.dart';
import '../../domain/usecases/supprimer_produit.dart';

// ───── Events ─────
abstract class VendeurProduitEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// `statut` null = tous les produits ; sinon en_attente / valide / rejete.
class LoadMesProduits extends VendeurProduitEvent {
  final String? statut;
  LoadMesProduits({this.statut});
  @override
  List<Object?> get props => [statut];
}

class SupprimerProduit extends VendeurProduitEvent {
  final String id;
  SupprimerProduit(this.id);
  @override
  List<Object?> get props => [id];
}

// ───── States ─────
abstract class VendeurProduitState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VendeurProduitLoading extends VendeurProduitState {}

class VendeurProduitLoaded extends VendeurProduitState {
  final List<ProduitModel> produits;
  VendeurProduitLoaded(this.produits);
  @override
  List<Object?> get props => [produits];
}

class VendeurProduitError extends VendeurProduitState {
  final String message;
  VendeurProduitError(this.message);
  @override
  List<Object?> get props => [message];
}

// ───── Bloc ─────
class VendeurProduitBloc extends Bloc<VendeurProduitEvent, VendeurProduitState> {
  final GetMesProduits getMesProduits;
  final SupprimerProduitUsecase supprimerProduit;

  /// Dernier filtre appliqué, réutilisé après une suppression pour rester
  /// sur le même onglet.
  String? _statutCourant;

  VendeurProduitBloc({
    required this.getMesProduits,
    required this.supprimerProduit,
  }) : super(VendeurProduitLoading()) {
    on<LoadMesProduits>(_onLoad);
    on<SupprimerProduit>(_onSupprimer);
  }

  Future<void> _reloadOrError(Emitter<VendeurProduitState> emit) async {
    final result = await getMesProduits(statut: _statutCourant);
    result.fold(
      (failure) => emit(VendeurProduitError(failure.errorMessage)),
      (produits) => emit(VendeurProduitLoaded(produits)),
    );
  }

  Future<void> _onLoad(LoadMesProduits event, Emitter<VendeurProduitState> emit) async {
    _statutCourant = event.statut;
    emit(VendeurProduitLoading());
    await _reloadOrError(emit);
  }

  Future<void> _onSupprimer(SupprimerProduit event, Emitter<VendeurProduitState> emit) async {
    final result = await supprimerProduit(event.id);
    await result.fold(
      (failure) async => emit(VendeurProduitError(failure.errorMessage)),
      (_) => _reloadOrError(emit),
    );
  }
}
