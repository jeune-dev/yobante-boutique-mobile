import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/avis_repository.dart';
import 'avis_event.dart';
import 'avis_state.dart';

class AvisBloc extends Bloc<AvisEvent, AvisState> {
  final AvisRepository repository;

  AvisBloc(this.repository) : super(AvisInitial()) {
    on<LoadAvisBoutique>(_onLoadBoutique);
    on<LoadMesAvis>(_onLoadMesAvis);
    on<LoadAvisRecus>(_onLoadAvisRecus);
    on<CreerAvis>(_onCreer);
    on<ModifierAvis>(_onModifier);
    on<SupprimerAvis>(_onSupprimer);
    on<RepondreAvis>(_onRepondre);
  }

  Future<void> _onLoadBoutique(
      LoadAvisBoutique event, Emitter<AvisState> emit) async {
    emit(AvisLoading());
    final result = await repository.avisParBoutique(event.boutiqueId);
    result.fold(
      (f) => emit(AvisError(f.errorMessage)),
      (list) => emit(AvisListeLoaded(list)),
    );
  }

  Future<void> _onLoadMesAvis(LoadMesAvis event, Emitter<AvisState> emit) async {
    emit(AvisLoading());
    final result = await repository.mesAvis();
    result.fold(
      (f) => emit(AvisError(f.errorMessage)),
      (list) => emit(AvisListeLoaded(list)),
    );
  }

  Future<void> _onLoadAvisRecus(LoadAvisRecus event, Emitter<AvisState> emit) async {
    emit(AvisLoading());
    final result = await repository.avisRecus();
    result.fold(
      (f) => emit(AvisError(f.errorMessage)),
      (list) => emit(AvisListeLoaded(list)),
    );
  }

  Future<void> _onCreer(CreerAvis event, Emitter<AvisState> emit) async {
    emit(AvisLoading());
    final result = await repository.creerAvis(
        note: event.note, commentaire: event.commentaire, boutiqueId: event.boutiqueId);
    result.fold(
      (f) => emit(AvisError(f.errorMessage)),
      (_) => add(LoadAvisBoutique(event.boutiqueId)),
    );
  }

  Future<void> _onModifier(ModifierAvis event, Emitter<AvisState> emit) async {
    final result = await repository.modifierAvis(event.id,
        note: event.note, commentaire: event.commentaire);
    result.fold(
      (f) => emit(AvisError(f.errorMessage)),
      (_) => add(LoadMesAvis()),
    );
  }

  Future<void> _onSupprimer(SupprimerAvis event, Emitter<AvisState> emit) async {
    final result = await repository.supprimerAvis(event.avisId);
    result.fold(
      (f) => emit(AvisError(f.errorMessage)),
      (_) => add(LoadMesAvis()),
    );
  }

  Future<void> _onRepondre(RepondreAvis event, Emitter<AvisState> emit) async {
    final result = await repository.repondre(event.avisId, event.reponse);
    result.fold(
      (f) => emit(AvisError(f.errorMessage)),
      (_) => add(LoadAvisRecus()),
    );
  }
}
