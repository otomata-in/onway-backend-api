import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io_client;
import '../config/app_config.dart';
import '../models/community_models.dart';
import 'api_service.dart';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io_client.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  final _messageController = StreamController<CommunityMessage>.broadcast();
  Stream<CommunityMessage> get messageStream => _messageController.stream;

  final _waypointController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get waypointStream => _waypointController.stream;

  final _locationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;

  void connect({String? token}) {
    if (_socket != null && _socket!.connected) return;

    final authToken = token ?? TeritoryApiService.instance.accessToken;

    try {
      _socket = io_client.io(
        AppConfig.socketUrl,
        io_client.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .setAuth({'token': authToken})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        debugPrint('🔌 [Teritory Socket] Connected to ${AppConfig.socketUrl}');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('🔌 [Teritory Socket] Disconnected');
      });

      _socket!.onConnectError((err) {
        _isConnected = false;
        debugPrint('⚠️ [Teritory Socket] Connect Error: $err');
      });

      // Community chat events
      _socket!.on('new_message', (data) {
        if (data is Map<String, dynamic>) {
          try {
            final msg = CommunityMessage.fromJson(data);
            _messageController.add(msg);
          } catch (e) {
            debugPrint('⚠️ [Teritory Socket] Parse error for new_message: $e');
          }
        }
      });

      // Trip live events
      _socket!.on('waypoint_validated', (data) {
        if (data is Map<String, dynamic>) {
          _waypointController.add(data);
        }
      });

      _socket!.on('participant_location', (data) {
        if (data is Map<String, dynamic>) {
          _locationController.add(data);
        }
      });
    } catch (e) {
      debugPrint('⚠️ [Teritory Socket] Init failed: $e');
    }
  }

  void joinCommunity(String communityId) {
    if (_socket == null) connect();
    _socket?.emit('join_community', {'communityId': communityId});
  }

  void leaveCommunity(String communityId) {
    _socket?.emit('leave_community', {'communityId': communityId});
  }

  void joinTrip(String tripId) {
    if (_socket == null) connect();
    _socket?.emit('join_trip', {'tripId': tripId});
  }

  void leaveTrip(String tripId) {
    _socket?.emit('leave_trip', {'tripId': tripId});
  }

  void sendTripLocation(String tripId, double lat, double lng) {
    _socket?.emit('trip_location_update', {
      'tripId': tripId,
      'latitude': lat,
      'longitude': lng,
    });
  }

  void sendTyping(String communityId, bool isTyping) {
    _socket?.emit('chat_typing', {
      'communityId': communityId,
      'isTyping': isTyping,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
