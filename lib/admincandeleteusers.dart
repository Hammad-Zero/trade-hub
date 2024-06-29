import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ShowpostsofOtherUserstoAdmin.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> _deleteUser(String userId) async {
    try {
      // Fetch user document to get the UID
      DocumentSnapshot userDoc = await usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      // Get UID from the document data
      String uid = userDoc['id'];

      // Deleting the user from Firebase Auth
      await FirebaseAuth.instance.currentUser!.delete();

      // Delete user document from 'users' collection
      await usersCollection.doc(userId).delete();

      // Delete associated data from other collections
      await _deleteUserRelatedData(uid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User and related data deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }

  Future<void> _deleteUserRelatedData(String userId) async {
    // Delete documents from 'user' collection where uploaderId matches userId
    QuerySnapshot userQuerySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('uploaderId', isEqualTo: userId)
        .get();

    for (QueryDocumentSnapshot userDoc in userQuerySnapshot.docs) {
      await userDoc.reference.delete();
    }

    // Delete documents from 'requests' collection where requester_id or uploader_id matches userId
    QuerySnapshot requestQuerySnapshot = await FirebaseFirestore.instance
        .collection('requests')
        .where('requester_id', isEqualTo: userId)
        .get();

    for (QueryDocumentSnapshot requestDoc in requestQuerySnapshot.docs) {
      await requestDoc.reference.delete();
    }

    QuerySnapshot requestQuerySnapshot2 = await FirebaseFirestore.instance
        .collection('requests')
        .where('uploader_id', isEqualTo: userId)
        .get();

    for (QueryDocumentSnapshot requestDoc in requestQuerySnapshot2.docs) {
      await requestDoc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final userDocs = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot userDoc = userDocs[index];
              Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

              String userId = userDoc.id;
              String username = userData['username'] ?? 'No Name';
              String email = userData['email'] ?? 'No Email';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(email, style: TextStyle(fontSize: 16)),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () => _deleteUser(userId),
                            style: ElevatedButton.styleFrom(primary: Colors.red),
                            child: Text('Delete User'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShowPostsScreen(userId: userId),
                                ),
                              );
                            },
                            child: Text('Show Posts'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
