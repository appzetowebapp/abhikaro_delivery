// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:webview_master_app/config/app_config.dart';

// /// Background message handler for Firebase Cloud Messaging
// /// This must be a top-level function
// /// Handles notifications when app is in background or terminated state
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   debugPrint('📨 Background message received: ${message.messageId}');
//   debugPrint('📨 Message data: ${message.data}');

//   // Initialize notification plugin for background messages
//   final FlutterLocalNotificationsPlugin notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // Use AppConfig for consistency
//   const AndroidInitializationSettings androidSettings =
//       AndroidInitializationSettings(AppConfig.notificationIcon);

//   const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
//     requestAlertPermission: true,
//     requestBadgePermission: true,
//     requestSoundPermission: true,
//   );

//   const InitializationSettings initSettings = InitializationSettings(
//     android: androidSettings,
//     iOS: iosSettings,
//   );

//   await notificationsPlugin.initialize(initSettings);

//   // Create notification channel for Android using AppConfig
//   final AndroidNotificationChannel channel = AndroidNotificationChannel(
//     AppConfig.notificationChannelId,
//     AppConfig.notificationChannelName,
//     description: AppConfig.notificationChannelDescription,
//     importance: Importance.high,
//     playSound: true,
//     enableVibration: true,
//     showBadge: true,
//     enableLights: true,
//     ledColor: AppConfig.notificationColor,
//   );

//   await notificationsPlugin
//       .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);

//   RemoteNotification? notification = message.notification;
//   Map<String, dynamic>? data = message.data;

//   // Create unique ID for this notification
//   final String notificationId = message.messageId ??
//       '${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

//   debugPrint('📨 Background notification ID: $notificationId');

//   // Handle notification payload (when app is in background/terminated)
//   if (notification != null) {
//     // Android notification details using AppConfig
//     final AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       AppConfig.notificationChannelId, // Must match channel ID
//       AppConfig.notificationChannelName,
//       channelDescription: AppConfig.notificationChannelDescription,
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//       enableVibration: true,
//       icon: AppConfig.notificationIcon,
//       showWhen: true,
//       styleInformation: const BigTextStyleInformation(''),
//       color: AppConfig.notificationColor,
//     );

//     // iOS notification details
//     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );

//     final NotificationDetails notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     // Show notification
//     // Use a hash of the notification ID to generate a consistent integer ID
//     // This prevents duplicate notifications even if the same message is processed multiple times
//     final int localNotificationId = notificationId.hashCode.abs() % 2147483647;

//     await notificationsPlugin.show(
//       localNotificationId,
//       notification.title ?? 'Notification',
//       notification.body ?? '',
//       notificationDetails,
//       payload: data.toString(),
//     );

//     debugPrint(
//         '✅ Background notification shown: ${notification.title} (ID: $localNotificationId)');
//   } else if (data.isNotEmpty) {
//     // Handle data-only messages (messages without notification payload)
//     debugPrint('📨 Data-only message received in background');
//     final title = data['title']?.toString() ?? 'Notification';
//     final body = data['body']?.toString() ?? data['message']?.toString() ?? '';

//     // Android notification details using AppConfig
//     final AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       AppConfig.notificationChannelId,
//       AppConfig.notificationChannelName,
//       channelDescription: AppConfig.notificationChannelDescription,
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//       enableVibration: true,
//       icon: AppConfig.notificationIcon,
//       showWhen: true,
//       styleInformation: const BigTextStyleInformation(''),
//       color: AppConfig.notificationColor,
//     );

//     // iOS notification details
//     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );

//     final NotificationDetails notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     // Generate notification ID from data
//     final int localNotificationId = notificationId.hashCode.abs() % 2147483647;

//     await notificationsPlugin.show(
//       localNotificationId,
//       title,
//       body,
//       notificationDetails,
//       payload: data.toString(),
//     );

//     debugPrint(
//         '✅ Background data-only notification shown: $title (ID: $localNotificationId)');
//   }
// }










import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' hide NotificationVisibility;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_master_app/config/app_config.dart';

/// Background message handler for Firebase Cloud Messaging
/// This must be a top-level function
/// Handles notifications when app is in background or terminated state
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Flutter is initialized for the isolate
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('📨 [BG] Background message received');
    final data = message.data;
    debugPrint('📨 [BG] Data: $data');

    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await notificationsPlugin.initialize(initSettings);
    debugPrint('✅ [BG] Plugin Init Done');

    // Determine if it's an order
    final type = data['type']?.toString().toLowerCase() ?? '';
    final isOrder = type.contains('order');
    debugPrint('🔔 [BG] isOrder: $isOrder');

    if (isOrder) {
        // Try to share with overlay
        try {
          await FlutterOverlayWindow.shareData(jsonEncode({
            'type': 'NEW_ORDER',
            'orderId': data['orderId'] ?? data['id'],
            'title': 'New Order',
            'body': 'You have a new delivery order',
          }));
          debugPrint('✅ [BG] Overlay Updated');
        } catch (e) {
             debugPrint('⚠️ [BG] Overlay Share Error: $e');
        }

        // Initialize Background Service if it's not running and start the ringtone
        try {
          final service = FlutterBackgroundService();
          if (await service.isRunning()) {
            service.invoke('startRingtone');
            debugPrint('🔔 [BG] Invoked background service ringtone');
          } else {
            debugPrint('⚠️ [BG] Background service not running, starting it...');
            await service.startService();
            // Wait a moment for service to start then invoke
            Future.delayed(const Duration(seconds: 2), () {
              service.invoke('startRingtone');
            });
          }
        } catch (e) {
          debugPrint('❌ [BG] Error invoking background service: $e');
        }

        // Create Channel with Custom Sound (Back-up)
        const channelId = 'critical_order_alerts_v5';
        const channelName = 'Direct Order Alerts';
        
        final androidImplementation = notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          debugPrint('🔧 [BG] Creating Channel: $channelId');
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              importance: Importance.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('order_ringtone'),
              enableVibration: true,
              showBadge: true,
            ),
          );
          debugPrint('✅ [BG] Channel Ready');
        }

        // Show Notification
        await notificationsPlugin.show(
          1000001, // Fixed ID for orders
          'NEW ORDER ARRIVED! 🔔',
          'Order ID: ${data['orderId'] ?? 'New Request'}',
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              sound: const RawResourceAndroidNotificationSound('order_ringtone'),
              enableVibration: true,
              vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]),
              ongoing: true,
              autoCancel: false,
              fullScreenIntent: true,
              additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT (Looping)
              category: AndroidNotificationCategory.call,
              visibility: NotificationVisibility.public,
              icon: '@mipmap/ic_launcher',
              styleInformation: const BigTextStyleInformation(''),
              color: Colors.red,
            ),
            iOS: const DarwinNotificationDetails(
              presentSound: true,
              sound: 'order_ringtone.mp3',
              interruptionLevel: InterruptionLevel.critical,
            ),
          ),
          payload: jsonEncode(data),
        );
        debugPrint('✅ [BG] Final Show Called');
    } else {
        debugPrint('ℹ️ [BG] Skipping non-order message');
    }
  } catch (e, stack) {
    debugPrint('❌ [BG] FATAL ERROR: $e');
    debugPrint('❌ [BG] STACK: $stack');
  }
}
