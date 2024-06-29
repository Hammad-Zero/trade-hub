import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Chat.dart';


class BidsScreen extends StatefulWidget {
  final String auctionId;

  BidsScreen({required this.auctionId});

  @override
  _BidsScreenState createState() => _BidsScreenState();
}

class _BidsScreenState extends State<BidsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String userId = '';
  String username='';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchUserId();

  }
  void _fetchUserId() async {
    try {
      DocumentSnapshot auctionDoc = await FirebaseFirestore.instance
          .collection('Auctions')
          .doc(widget.auctionId)
          .get();

      if (auctionDoc.exists) {
        setState(() {
          userId = auctionDoc['userId'] ?? '';
        });
      } else {
        print('Auction document does not exist.');
      }
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (auctionDoc.exists) {
        setState(() {
          username = userDoc['username'] ?? '';
        });
      } else {
        print('Auction document does not exist.');
      }

    } catch (e) {
      print('Error fetching userId: $e');
    }

  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bids and Comments'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bids_and_comments')
            .where('auctionId', isEqualTo: widget.auctionId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('No bids or comments yet.');
            return Center(child: Text('No bids or comments yet.'));
          }

          print('Number of bids: ${snapshot.data!.docs.length}');

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var bid = snapshot.data!.docs[index];
              return _buildBidCard(bid);
            },
          );
        },
      ),
    );
  }

  Widget _buildBidCard(DocumentSnapshot bid) {
    var data = bid.data() as Map<String, dynamic>;

    // Use a default value of 0.0 if 'price' is null
    double price = data['price'] ?? 0.0;
    String user = data['user'] ?? 'Unknown User'; // Provide default value for 'user'

    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text('Price: \$${price.toStringAsFixed(2)}'),
        subtitle: Text('User: $user'),
        trailing: ElevatedButton(
          onPressed: () {
            final User? user = _auth.currentUser;
            final String? currentUserId = user?.uid;
            Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatScreen(senderId: currentUserId.toString(), receiverId: userId, receiverName: username))); // Ensure that user is not null
          },
          child: Text('Send Message'),
        ),
      ),
    );
  }

  void _sendMessage(String userId) {
    // Implement your logic to handle sending a message to the user
    // Example: Navigate to a messaging screen or open a messaging service
    print('Sending message to user: $userId');
    // Add your implementation here
  }
}
