import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:switchlink/screens/loginScreen.dart';

class UserNotificationsScreen extends StatefulWidget {
  @override
  _UserNotificationsScreenState createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  String? fcmToken;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _getUserEmail();
    _getFCMToken();
  }

  void _getUserEmail() {
    userEmail = FirebaseAuth.instance.currentUser?.email;
    setState(() {});
  }

  Future<void> _getFCMToken() async {
    fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null && userEmail != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({"fcmToken": fcmToken});
    }
    setState(() {});
  }

  void logout() async {
    await FirebaseAuth.instance.signOut(); 
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen())); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade900,
        title: Text("Notifications", style: TextStyle(color: Colors.white)),
        centerTitle: true,
         actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white), 
            onPressed: logout, 
          ),
        ],
      ),
      body: userEmail == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("notifications")
                  .where("email", isEqualTo: userEmail)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("Firestore Error: ${snapshot.error}");
                  return Center(child: Text("Error loading notifications!"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("📭 No Notifications Found"));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var notification = snapshot.data!.docs[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      child: ListTile(
                        title: Text(notification["title"], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(notification["description"]),
                        trailing: Icon(Icons.notifications, color: Colors.indigo.shade900),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
