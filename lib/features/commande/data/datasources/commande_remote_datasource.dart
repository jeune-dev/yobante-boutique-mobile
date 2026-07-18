import 'package:dio/dio.dart';
import '../models/adresse_model.dart';
import '../models/commande_model.dart';
import '../models/paiement_model.dart';
import '../../../../core/constants/api_endpoints.dart';

abstract class CommandeRemoteDataSource {
  Future<CommandeModel> creerCommande(Map<String, dynamic> body);
  Future<List<CommandeModel>> mesCommandes({String? statut});
  Future<CommandeModel> getCommande(String id);
  Future<CommandeModel> annuler(String id);

  /// Démarre le paiement de la commande. Le mode de règlement a été fixé au
  /// moment de commander : il n'est pas renvoyé ici.
  Future<PaiementModel> payer(String id);

  /// État courant du paiement, pour savoir si le règlement a abouti.
  Future<PaiementModel> statutPaiement(String id);

  Future<List<AdresseModel>> adresses();
}

class CommandeRemoteDataSourceImpl implements CommandeRemoteDataSource {
  final Dio dio;
  CommandeRemoteDataSourceImpl(this.dio);

  /// Les réponses ont la forme `{ success, message, data: { <cle>: ... } }`.
  dynamic _contenu(dynamic reponse, String cle) {
    if (reponse is! Map) return null;
    final data = reponse['data'];
    if (data is Map && data[cle] != null) return data[cle];
    if (reponse[cle] != null) return reponse[cle];
    return data;
  }

  List<CommandeModel> _parseListe(dynamic reponse) {
    final brut = _contenu(reponse, 'commandes');
    if (brut is! List) return const [];
    return brut.map((e) => CommandeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  CommandeModel _parseUne(dynamic reponse) {
    final brut = _contenu(reponse, 'commande');
    return CommandeModel.fromJson(Map<String, dynamic>.from(brut as Map));
  }

  @override
  Future<CommandeModel> creerCommande(Map<String, dynamic> body) async {
    final res = await dio.post(CommandeEndpoints.commandes, data: body);
    return _parseUne(res.data);
  }

  @override
  Future<List<CommandeModel>> mesCommandes({String? statut}) async {
    final res = await dio.get(
      CommandeEndpoints.commandes,
      queryParameters: statut != null ? {'statut': statut} : null,
    );
    return _parseListe(res.data);
  }

  @override
  Future<CommandeModel> getCommande(String id) async {
    final res = await dio.get(CommandeEndpoints.commande(id));
    return _parseUne(res.data);
  }

  @override
  Future<CommandeModel> annuler(String id) async {
    final res = await dio.patch(CommandeEndpoints.annuler(id));
    return _parseUne(res.data);
  }

  @override
  Future<PaiementModel> payer(String id) async {
    final res = await dio.post(CommandeEndpoints.payer(id));
    return PaiementModel.fromJson(
      Map<String, dynamic>.from(_contenu(res.data, 'paiement') as Map),
    );
  }

  @override
  Future<PaiementModel> statutPaiement(String id) async {
    final res = await dio.get(CommandeEndpoints.paiement(id));
    return PaiementModel.fromJson(
      Map<String, dynamic>.from(_contenu(res.data, 'paiement') as Map),
    );
  }

  @override
  Future<List<AdresseModel>> adresses() async {
    final res = await dio.get(CompteEndpoints.adresses);
    final brut = _contenu(res.data, 'adresses');
    if (brut is! List) return const [];
    return brut.map((e) => AdresseModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
