import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🔹 Local Notification Show Function
Future<void> showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    "channel_id",
    "channel_name",
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await _flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? "New Message",
    message.notification?.body ?? "Check your app",
    platformDetails,
  );
}


Future<void> showFirestoreNotification(String title, String description) async {
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    "channel_id",
    "channel_name",
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await _flutterLocalNotificationsPlugin.show(
    0,
    title,
    description,
    platformDetails,
  );
}


Future<void> saveTokenToFirestore() async {
  String? token = await _firebaseMessaging.getToken();
  String? uid = FirebaseAuth.instance.currentUser?.uid;

  if (token != null && uid != null) {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background Notification Received: ${message.notification?.title}");
}

// Firebase Messaging Setup
Future<void> setupFCM() async {
  await saveTokenToFirestore();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  NotificationSettings settings = await _firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("Notification Permission Granted");
  } else {
    print("Notification Permission Denied");
  }

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await _flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print("User Clicked Notification");
    },
  );

  // Foreground Notification Handle 
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground Notification: ${message.notification?.title}");
    showNotification(message);
  });

  // Background aur Terminated Notification Handle 
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("User Opened Notification: ${message.notification?.title}");
  });

  // 🔹 Firestore Changes Listen Kare
  FirebaseFirestore.instance
      .collection('notifications')
      .snapshots()
      .listen((snapshot) async {
    String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;  

    for (var doc in snapshot.docChanges) {
      if (doc.type == DocumentChangeType.added) {
        String? documentEmail = doc.doc['email'];  
        // 🔹 Sirf tabhi notification bhejo jab dono emails match kare
        if (currentUserEmail != null && documentEmail != null && currentUserEmail == documentEmail) {
          log("currentEmail: ${currentUserEmail}");
          log("documentEmail: ${documentEmail}");
          print("Email Matched: Showing Notification");
          showFirestoreNotification(doc.doc['title'], doc.doc['description']);
        } else {
          print("Email Mismatch: No Notification");
        }
      }
    }
  });


}
