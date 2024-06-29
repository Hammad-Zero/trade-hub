import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<UserRecord> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    // Placeholder: Replace with actual method to fetch users
    setState(() {
      users = [
        UserRecord(uid: 'user1', email: 'user1@example.com'),
        UserRecord(uid: 'user2', email: 'user2@example.com')
      ];
    });
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _auth.currentUser!.delete();
      fetchUsers(); // Refresh user list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin - Delete Users')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(users[index].email),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => deleteUser(users[index].uid),
            ),
          );
        },
      ),
    );
  }
}

class UserRecord {
  final String uid;
  final String email;

  UserRecord({required this.uid, required this.email});
}
