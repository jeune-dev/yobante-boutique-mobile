import 'package:equatable/equatable.dart';

abstract class AvisEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAvisBoutique extends AvisEvent {
  final String boutiqueId;
  LoadAvisBoutique(this.boutiqueId);
  @override
  List<Object?> get props => [boutiqueId];
}

class LoadMesAvis extends AvisEvent {}

class LoadAvisRecus extends AvisEvent {}

class CreerAvis extends AvisEvent {
  final int note;
  final String commentaire;
  final String boutiqueId;
  CreerAvis({required this.note, required this.commentaire, required this.boutiqueId});
  @override
  List<Object?> get props => [note, commentaire, boutiqueId];
}

class ModifierAvis extends AvisEvent {
  final String id;
  final int? note;
  final String? commentaire;
  ModifierAvis(this.id, {this.note, this.commentaire});
  @override
  List<Object?> get props => [id, note, commentaire];
}

class SupprimerAvis extends AvisEvent {
  final String avisId;
  SupprimerAvis(this.avisId);
  @override
  List<Object?> get props => [avisId];
}

class RepondreAvis extends AvisEvent {
  final String avisId;
  final String reponse;
  RepondreAvis(this.avisId, this.reponse);
  @override
  List<Object?> get props => [avisId, reponse];
}
