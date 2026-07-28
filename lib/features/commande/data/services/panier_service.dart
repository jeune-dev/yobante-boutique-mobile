import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/panier_item.dart';

/// Service de gestion du panier local (persisté via SharedPreferences).
///
/// Panier **multi-boutiques** : les produits de vendeurs différents cohabitent,
/// sont regroupés par boutique à l'affichage, et **commandés séparément** (une
/// commande par boutique, conformément à la règle backend « 1 commande = 1
/// vendeur »).
///
/// Conservé pour compatibilité : n'est plus levé (le panier accepte plusieurs
/// vendeurs), mais l'ancien code qui l'attrape continue de compiler.
class PanierVendeurDifferentException implements Exception {
  final String message;
  PanierVendeurDifferentException([
    this.message =
        'Votre panier contient déjà des produits d\'une autre boutique.',
  ]);
  @override
  String toString() => message;
}

class PanierService extends ChangeNotifier {
  static const String _key = 'panier_items';
  final SharedPreferences prefs;

  List<PanierItem> _items = [];

  PanierService({required this.prefs}) {
    _charger();
  }

  List<PanierItem> get items => List.unmodifiable(_items);
  int get nombreArticles => _items.fold(0, (sum, it) => sum + it.quantite);
  double get total => _items.fold(0.0, (sum, it) => sum + it.sousTotal);
  bool get estVide => _items.isEmpty;
  String? get vendeurId => _items.isEmpty ? null : _items.first.vendeurId;

  void _charger() {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) => PanierItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _items = [];
    }
  }

  Future<void> _sauvegarder() async {
    final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
    notifyListeners();
  }

  /// Ajoute un produit. Si déjà présent, incrémente la quantité.
  /// Multi-boutiques : aucun blocage si le produit vient d'un autre vendeur.
  Future<void> ajouter(PanierItem item) async {
    final index = _items.indexWhere((e) => e.produitId == item.produitId);
    if (index >= 0) {
      _items[index].quantite += item.quantite;
    } else {
      _items.add(item);
    }
    await _sauvegarder();
  }

  Future<void> changerQuantite(String produitId, int quantite) async {
    final index = _items.indexWhere((e) => e.produitId == produitId);
    if (index < 0) return;
    if (quantite <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantite = quantite;
    }
    await _sauvegarder();
  }

  Future<void> retirer(String produitId) async {
    _items.removeWhere((e) => e.produitId == produitId);
    await _sauvegarder();
  }

  Future<void> vider() async {
    _items = [];
    await prefs.remove(_key);
    notifyListeners();
  }

  /// Transforme le panier en payload `items` pour l'API de création de commande.
  List<Map<String, dynamic>> toApiItems() {
    return _items
        .map((e) => {'produitId': e.produitId, 'quantite': e.quantite})
        .toList();
  }

  // ── Sélection d'articles ───────────────────────────────────────────────────
  //
  // Le client coche ce qu'il veut commander maintenant : le reste attend dans
  // le panier. Une commande porte donc sur un sous-ensemble d'articles, pas sur
  // le panier entier.

  /// Articles dont le produit figure dans [produitIds].
  List<PanierItem> selection(Set<String> produitIds) =>
      _items.where((e) => produitIds.contains(e.produitId)).toList();

  /// Montant des seuls articles sélectionnés.
  double totalSelection(Set<String> produitIds) =>
      selection(produitIds).fold(0.0, (somme, e) => somme + e.sousTotal);

  /// Nombre d'unités sélectionnées, toutes lignes confondues.
  int nombreArticlesSelection(Set<String> produitIds) =>
      selection(produitIds).fold(0, (somme, e) => somme + e.quantite);

  /// Payload `items` limité à la sélection.
  List<Map<String, dynamic>> toApiItemsSelection(Set<String> produitIds) =>
      selection(produitIds)
          .map((e) => {'produitId': e.produitId, 'quantite': e.quantite})
          .toList();

  /// Retire les articles commandés, en laissant les autres dans le panier.
  Future<void> retirerSelection(Set<String> produitIds) async {
    _items.removeWhere((e) => produitIds.contains(e.produitId));
    await _sauvegarder();
  }
}
