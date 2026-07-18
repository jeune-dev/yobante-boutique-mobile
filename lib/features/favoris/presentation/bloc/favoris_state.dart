import 'package:equatable/equatable.dart';

import '../../../home/data/models/boutique_model.dart';

abstract class FavorisState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FavorisInitial extends FavorisState {}

class FavorisLoading extends FavorisState {}

class FavorisLoaded extends FavorisState {
  final List<BoutiqueModel> boutiques;
  FavorisLoaded(this.boutiques);
  @override
  List<Object?> get props => [boutiques];
}

class FavorisError extends FavorisState {
  final String message;
  FavorisError(this.message);
  @override
  List<Object?> get props => [message];
}
