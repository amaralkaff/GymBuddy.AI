// lib/services/pushup_service.dart
import 'package:test_1/services/api_service.dart';

class PushupService {
  final APIService _api = APIService();

  Future<Map<String, dynamic>> submitPushups({
    required int weight,
    required int pushups,
  }) async {
    try {
      return await _api.post('pushup', {
        'weight': weight,
        'pushUps': pushups,
      });
    } catch (e) {
      throw Exception('Failed to submit pushups: $e');
    }
  }
}