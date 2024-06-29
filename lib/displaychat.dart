import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tradehub/Chat.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> fetchMessageUsers() async {
    QuerySnapshot sentToCurrentUserSnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('receiver', isEqualTo: currentUserId)
        .get();

    QuerySnapshot sentByCurrentUserSnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('sender', isEqualTo: currentUserId)
        .get();

    Set<String> sentToCurrentUserIds = sentToCurrentUserSnapshot.docs
        .map((doc) => doc['sender'] as String)
        .toSet();

    Set<String> sentByCurrentUserIds = sentByCurrentUserSnapshot.docs
        .map((doc) => doc['receiver'] as String)
        .toSet();

    Set<String> allMessageUserIds = {...sentToCurrentUserIds, ...sentByCurrentUserIds};

    List<Map<String, dynamic>> usersWithLastMessage = [];

    for (String userId in allMessageUserIds) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;

      if (userData != null) {
        String userName = userData['username'];

        QuerySnapshot lastMessageSnapshot = await FirebaseFirestore.instance
            .collection('messages')
            .where('sender', isEqualTo: currentUserId)
            .where('receiver', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        String lastMessage = '';

        if (lastMessageSnapshot.docs.isNotEmpty) {
          lastMessage = lastMessageSnapshot.docs.first['text'];
        }

        usersWithLastMessage.add({
          'userId': userId,
          'userName': userName,
          'lastMessage': lastMessage,
        });
      }
    }

    return usersWithLastMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        backgroundColor: Colors.purple,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchMessageUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error fetching users: ${snapshot.error}');
            return Center(child: Text('Something went wrong'));
          }

          List<Map<String, dynamic>> usersWithLastMessage = snapshot.data ?? [];

          if (usersWithLastMessage.isEmpty) {
            return Center(child: Text('No chats found'));
          }

          return ListView.builder(
            itemCount: usersWithLastMessage.length,
            itemBuilder: (context, index) {
              String userId = usersWithLastMessage[index]['userId'];
              String userName = usersWithLastMessage[index]['userName'];
              String lastMessage = usersWithLastMessage[index]['lastMessage'];

              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    // You can replace this with a user profile image
                    child: Text(userName[0]),
                  ),
                  title: Text(userName),
                  subtitle: Text(lastMessage),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(senderId: currentUserId, receiverId: userId, receiverName: userName)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
