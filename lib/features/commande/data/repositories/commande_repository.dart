import '../datasources/commande_remote_datasource.dart';
import '../models/adresse_model.dart';
import '../models/commande_model.dart';
import '../models/paiement_model.dart';

/// Repository commande — fine couche au-dessus du datasource.
class CommandeRepository {
  final CommandeRemoteDataSource remote;
  CommandeRepository(this.remote);

  /// Le panier est côté client (PanierService) : on l'envoie au backend avec la commande.
  Future<CommandeModel> creerCommande({
    required String adresseId,
    required String methode,
    required List<Map<String, dynamic>> items,
    String? note,
    DateTime? dateLivraisonSouhaitee,
  }) {
    return remote.creerCommande({
      'adresseId': adresseId,
      'methode': methode,
      'items': items,
      if (note != null && note.isNotEmpty) 'note': note,
      if (dateLivraisonSouhaitee != null)
        'dateLivraisonSouhaitee':
            dateLivraisonSouhaitee.toIso8601String().split('T').first,
    });
  }

  /// Crée une adresse de livraison ponctuelle (option « livrer ailleurs »).
  Future<AdresseModel> creerAdresse({
    required String nomComplet,
    required String telephone,
    required String rue,
    required String ville,
    String? region,
    String pays = 'Sénégal',
  }) {
    return remote.creerAdresse({
      'nomComplet': nomComplet,
      'telephone': telephone,
      'rue': rue,
      'ville': ville,
      if (region != null && region.isNotEmpty) 'region': region,
      'pays': pays,
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
