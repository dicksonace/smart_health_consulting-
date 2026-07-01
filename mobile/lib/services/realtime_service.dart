import 'dart:async';

import '../api/api_client.dart';

typedef RealtimeCallback = void Function(List<Map<String, dynamic>> events);

class RealtimeService {
  RealtimeService(this._api);

  final ApiClient _api;
  Timer? _timer;
  String? _lastSince;
  int? _doctorId;

  void startPolling({
    required RealtimeCallback onEvents,
    int? doctorId,
    Duration interval = const Duration(seconds: 3),
  }) {
    stopPolling();
    _doctorId = doctorId;
    _lastSince = DateTime.now().toUtc().toIso8601String();

    _timer = Timer.periodic(interval, (_) async {
      try {
        final data = await _api.get('/realtime/poll', query: {
          if (_lastSince != null) 'since': _lastSince,
          if (_doctorId != null) 'doctor_id': _doctorId,
        });
        final events = (data['events'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];
        if (events.isNotEmpty) {
          _lastSince = data['server_time'] as String? ?? DateTime.now().toUtc().toIso8601String();
          onEvents(events);
        }
      } catch (_) {}
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }
}
