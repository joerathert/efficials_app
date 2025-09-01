/// Stub implementation for Firebase messaging on web platform
/// This is a temporary solution to allow web builds while Firebase messaging
/// has compatibility issues with Flutter web

class FirebaseMessaging {
  static FirebaseMessaging get instance => FirebaseMessaging._();
  FirebaseMessaging._();
  
  Future<void> requestPermission({
    bool? alert,
    bool? announcement, 
    bool? badge,
    bool? carPlay,
    bool? criticalAlert,
    bool? provisional,
    bool? sound,
  }) async {
    // Web stub - no-op
  }
  
  Future<void> subscribeToTopic(String topic) async {
    // Web stub - no-op
  }
  
  Future<void> unsubscribeFromTopic(String topic) async {
    // Web stub - no-op
  }
  
  Future<String?> getToken() async {
    // Web stub - return null
    return null;
  }
  
  Stream<RemoteMessage> get onMessage => Stream.empty();
  Stream<RemoteMessage> get onMessageOpenedApp => Stream.empty();
  static Function(RemoteMessage)? onBackgroundMessage;
}

class RemoteMessage {
  final RemoteNotification? notification;
  final Map<String, dynamic>? data;
  
  RemoteMessage({this.notification, this.data});
}

class RemoteNotification {
  final String? title;
  final String? body;
  
  RemoteNotification({this.title, this.body});
}

enum AuthorizationStatus {
  authorized,
  denied,
  provisional,
  notDetermined,
}

class NotificationSettings {
  final AuthorizationStatus authorizationStatus;
  
  NotificationSettings({required this.authorizationStatus});
}