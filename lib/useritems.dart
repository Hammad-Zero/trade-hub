import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user; // Made nullable
  String? _contactDetail; // Made nullable
  String? _description; // Made nullable
  String? _desiredItem; // Made nullable
  String? _title; // Made nullable
  String? _imageUrl; // Made nullable

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _user = _auth.currentUser;
    if (_user!= null) {
      final userId = _user!.uid; // Use null-aware operator
      final userDocRef = _firestore.collection('users').doc(userId);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        setState(() {
          _contactDetail = userData?['contactDetail']; // Use null-aware operator
          _description = userData?['description']; // Use null-aware operator
          _desiredItem = userData?['desiredItem']; // Use null-aware operator
          _title = userData?['title']; // Use null-aware operator
          _imageUrl = userData?['image']; // Use null-aware operator
        });
      } else {
        print("No such user document!");
      }
    } else {
      print("User not logged in!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _imageUrl!= null
                  ? NetworkImage(_imageUrl!)
                  : null,
            ),
            SizedBox(height: 20),
            Text(
              _title?? '', // Use null-aware operator
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _description?? '', // Use null-aware operator
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Contact Detail: ${_contactDetail?? ''}', // Use null-aware operator
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Desired Item: ${_desiredItem?? ''}', // Use null-aware operator
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}