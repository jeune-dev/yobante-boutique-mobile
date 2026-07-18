import 'package:equatable/equatable.dart';

import '../../data/models/avis_model.dart';

abstract class AvisState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AvisInitial extends AvisState {}

class AvisLoading extends AvisState {}

class AvisListeLoaded extends AvisState {
  final List<AvisModel> avis;
  AvisListeLoaded(this.avis);
  @override
  List<Object?> get props => [avis];
}

class AvisActionSucces extends AvisState {
  final String message;
  AvisActionSucces(this.message);
  @override
  List<Object?> get props => [message];
}

class AvisError extends AvisState {
  final String message;
  AvisError(this.message);
  @override
  List<Object?> get props => [message];
}
