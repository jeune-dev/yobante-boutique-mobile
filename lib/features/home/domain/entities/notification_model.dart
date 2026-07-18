class NotificationModel {
  final String id;
  final String titre;
  final String message;
  final DateTime date;
  final bool lue;

  /// Nature de la notification : commande, paiement, produit…
  final String type;

  /// Contexte permettant d'ouvrir le bon écran (commandeId, produitId…).
  final Map<String, dynamic> donnees;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.date,
    required this.lue,
    this.type = '',
    this.donnees = const {},
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      date: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      // Le backend expose `lu` ; `lue` reste accepté par tolérance.
      lue: json['lu'] ?? json['lue'] ?? false,
      type: json['type']?.toString() ?? '',
      donnees: json['donnees'] is Map
          ? Map<String, dynamic>.from(json['donnees'] as Map)
          : const {},
    );
  }
}
