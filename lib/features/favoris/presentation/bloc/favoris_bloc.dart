import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/favoris_repository.dart';
import 'favoris_event.dart';
import 'favoris_state.dart';

class FavorisBloc extends Bloc<FavorisEvent, FavorisState> {
  final FavorisRepository repository;

  FavorisBloc(this.repository) : super(FavorisInitial()) {
    on<LoadFavoris>(_onLoad);
    on<AjouterFavori>(_onAjouter);
    on<SupprimerFavori>(_onSupprimer);
  }

  Future<void> _onLoad(LoadFavoris event, Emitter<FavorisState> emit) async {
    emit(FavorisLoading());
    final result = await repository.mesFavoris();
    result.fold(
      (f) => emit(FavorisError(f.errorMessage)),
      (list) => emit(FavorisLoaded(list)),
    );
  }

  Future<void> _onAjouter(AjouterFavori event, Emitter<FavorisState> emit) async {
    final result = await repository.ajouter(event.boutiqueId);
    result.fold(
      (f) => emit(FavorisError(f.errorMessage)),
      (_) => add(LoadFavoris()),
    );
  }

  Future<void> _onSupprimer(
      SupprimerFavori event, Emitter<FavorisState> emit) async {
    final result = await repository.supprimer(event.boutiqueId);
    result.fold(
      (f) => emit(FavorisError(f.errorMessage)),
      (_) => add(LoadFavoris()),
    );
  }
}
