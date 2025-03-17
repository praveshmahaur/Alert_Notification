import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:switchlink/screens/loginScreen.dart';

class Adminscreen extends StatefulWidget {
  @override
  _AdminscreenState createState() => _AdminscreenState();
}

class _AdminscreenState extends State<Adminscreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool? userExists;
  String? targetUserId;

  Future<void> checkUserExists() async {
    String email = emailController.text.trim();
    if (email.isEmpty) return;

    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    setState(() {
      if (querySnapshot.docs.isNotEmpty) {
        userExists = true;
        targetUserId = querySnapshot.docs.first.id;
        print("User Found: $targetUserId");
      } else {
        userExists = false;
        targetUserId = null;
        print("User Not Found!");
      }
    });
  }

  void sendNotification() async {
    String title = titleController.text;
    String description = descriptionController.text;
    String email = emailController.text;

    if (title.isEmpty || description.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please fill all fields!")));
      return;
    }

    if (targetUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User does not exist! Please check email.")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("notifications").add({
        "title": title,
        "description": description,
        "email": email,
        "userId": targetUserId,
        "timestamp": FieldValue.serverTimestamp(),
      });

      await sendFCMNotification(targetUserId!, title, description);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Notification Sent!")));

      titleController.clear();
      descriptionController.clear();
      emailController.clear();
      setState(() {
        userExists = null;
        targetUserId = null;
      });
    } catch (e) {
      print("Firestore Error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> sendFCMNotification(String userId, String title, String body) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc['fcmToken'] != null) {
        String userToken = userDoc['fcmToken'];

        await FirebaseMessaging.instance.sendMessage(
          to: userToken,
          data: {
            'title': title,
            'body': body,
          },
        );

        print("FCM Notification Sent to User: $userId");
      } else {
        print("User Token Not Found");
      }
    } catch (e) {
      print("Error Sending Notification: $e");
    }
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
        title: Text("Admin - Send Notification", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white), 
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: logout, 
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text("Title", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: "Enter notification title",
                ),
              ),
              SizedBox(height: 20),
              Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: "Enter notification description",
                ),
              ),
              SizedBox(height: 20),
              Text("User Email", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: "Enter user email",
                  suffixIcon: IconButton(
                    icon: userExists == null
                        ? Icon(Icons.search, color: Colors.indigo.shade900)
                        : userExists == true
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.cancel, color: Colors.red),
                    onPressed: checkUserExists,
                  ),
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade900,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Send Notification", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
