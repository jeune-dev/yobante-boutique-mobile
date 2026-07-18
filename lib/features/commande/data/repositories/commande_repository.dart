import '../datasources/commande_remote_datasource.dart';
import '../models/adresse_model.dart';
import '../models/commande_model.dart';
import '../models/paiement_model.dart';

/// Repository commande — fine couche au-dessus du datasource.
class CommandeRepository {
  final CommandeRemoteDataSource remote;
  CommandeRepository(this.remote);

  /// Le panier est côté serveur : la commande ne transmet donc pas les lignes,
  /// seulement l'adresse de livraison et le mode de règlement retenu.
  Future<CommandeModel> creerCommande({
    required String adresseId,
    required String methode,
    String? note,
  }) {
    return remote.creerCommande({
      'adresseId': adresseId,
      'methode': methode,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<List<CommandeModel>> mesCommandes({String? statut}) =>
      remote.mesCommandes(statut: statut);

  Future<CommandeModel> getCommande(String id) => remote.getCommande(id);

  Future<CommandeModel> annuler(String id) => remote.annuler(id);

  Future<PaiementModel> payer(String id) => remote.payer(id);

  Future<PaiementModel> statutPaiement(String id) => remote.statutPaiement(id);

  Future<List<AdresseModel>> adresses() => remote.adresses();
}
