// lib/core/services/notification_service.dart

import 'dart:async';
import '../api_client.dart';

class NotificationService {
  final ApiClient _api = ApiClient();
  Timer? _timer;
  int _nonLues = 0;

  int get nonLues => _nonLues;

  Future<Map<String, dynamic>> getNotifications({required String token}) async {
    return _api.get('/notifications/', token: token);
  }

  Future<Map<String, dynamic>> marquerLue({
    required String token,
    required int notifId,
  }) async {
    return _api.put('/notifications/$notifId/lue/', {}, token: token);
  }

  // ✅ Polling toutes les 30 secondes
  void demarrerPolling({
    required String token,
    required Function(List<dynamic>) onNouvellesNotifs,
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final res = await getNotifications(token: token);
        if (res['success'] == true) {
          final notifs = res['notifications'] as List<dynamic>? ?? [];
          final nonLues = notifs.where((n) => n['lu'] == 0 || n['lu'] == false).toList();
          _nonLues = nonLues.length;
          if (nonLues.isNotEmpty) onNouvellesNotifs(nonLues);
        }
      } catch (_) {}
    });
  }

  void arreterPolling() {
    _timer?.cancel();
    _timer = null;
  }
}