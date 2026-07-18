import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../home/domain/entities/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> notifications();
  Future<int> nombreNonLues();
  Future<void> marquerToutesLues();
  Future<void> marquerLue(String id);

  /// Jeton d'appareil pour le push. La route existe côté backend ; le jeton
  /// proviendra de firebase_messaging une fois le projet Firebase créé.
  Future<void> registerDeviceToken({required String token, required String platform});
  Future<void> unregisterDeviceToken(String token);
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final Dio dio;
  NotificationsRemoteDataSourceImpl(this.dio);

  /// Les réponses ont la forme `{ success, message, data: { <cle>: ... } }`.
  dynamic _contenu(dynamic reponse, String cle) {
    if (reponse is! Map) return null;
    final data = reponse['data'];
    if (data is Map && data[cle] != null) return data[cle];
    if (reponse[cle] != null) return reponse[cle];
    return null;
  }

  @override
  Future<List<NotificationModel>> notifications() async {
    final res = await dio.get(NotificationsEndpoints.notifications);
    final brut = _contenu(res.data, 'notifications');
    if (brut is! List) return const [];
    return brut.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<int> nombreNonLues() async {
    final res = await dio.get(NotificationsEndpoints.nonLues);
    final total = _contenu(res.data, 'total');
    return int.tryParse(total?.toString() ?? '') ?? 0;
  }

  @override
  Future<void> marquerToutesLues() async {
    await dio.patch(NotificationsEndpoints.toutesLues);
  }

  @override
  Future<void> marquerLue(String id) async {
    await dio.patch(NotificationsEndpoints.marquerLue(id));
  }

  @override
  Future<void> registerDeviceToken({required String token, required String platform}) async {
    await dio.post(
      NotificationsEndpoints.registerDeviceToken,
      data: {'token': token, 'plateforme': platform},
    );
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    await dio.post(NotificationsEndpoints.unregisterDeviceToken, data: {'token': token});
  }
}
