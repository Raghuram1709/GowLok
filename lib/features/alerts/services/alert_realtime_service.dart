import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertRealtimeService {
  static final AlertRealtimeService _instance = AlertRealtimeService._();

  factory AlertRealtimeService() {
    return _instance;
  }

  AlertRealtimeService._();

  RealtimeChannel? _channel;
  StreamController<void>? _controller;
  String? _currentFarmId;
  int _refCount = 0;

  Stream<void> get alertStream {
    _controller ??= StreamController<void>.broadcast();
    return _controller!.stream;
  }

  void subscribe(String farmId) {
    _refCount++;

    if (_currentFarmId == farmId && _channel != null) {
      return;
    }

    _forceUnsubscribe();

    _currentFarmId = farmId;
    _controller = StreamController<void>.broadcast();

    _channel = Supabase.instance.client.channel(
      'alerts:farm_id=eq.$farmId',
    );

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alerts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'farm_id',
            value: farmId,
          ),
          callback: (payload) {
            if (_controller != null && !_controller!.isClosed) {
              _controller!.add(null);
            }
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    _refCount--;
    if (_refCount <= 0) {
      _forceUnsubscribe();
      _refCount = 0;
    }
  }

  void _forceUnsubscribe() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }

    if (_controller != null && !_controller!.isClosed) {
      _controller!.close();
      _controller = null;
    }

    _currentFarmId = null;
  }
}
