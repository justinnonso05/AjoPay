import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background FCM message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;

  String? get currentToken => _currentToken;

  /// Initializes FCM listeners, requests permissions, and fetches the token.
  Future<void> initialize() async {
    // Request permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      
      // Set background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Get current FCM token
      try {
        _currentToken = await _messaging.getToken();
        debugPrint('FCM Token: $_currentToken');
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      // Listen to token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        syncTokenWithBackend(newToken);
      });

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground FCM notification: ${message.notification?.title}');
      });

      // Handle notification open/tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM notification opened app: ${message.data}');
      });
    }
  }

  /// Sends the current FCM token to the backend API.
  Future<void> syncTokenWithBackend(String? token) async {
    final tokenToSend = token ?? _currentToken;
    if (tokenToSend == null || tokenToSend.isEmpty) return;

    try {
      final authToken = await SecureStorageService().readAccessToken();
      if (authToken == null || authToken.isEmpty) return;

      final client = ApiClient();
      await client.post(
        ApiConstants.fcmToken,
        body: {'fcm_token': tokenToSend},
        headers: {'Authorization': 'Bearer $authToken'},
      );
      debugPrint('FCM Token successfully synced with backend.');
    } catch (e) {
      debugPrint('Failed to sync FCM Token with backend: $e');
    }
  }
}
