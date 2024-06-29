import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaceBidScreen extends StatefulWidget {
  final String auctionId;

  PlaceBidScreen({required this.auctionId});

  @override
  _PlaceBidScreenState createState() => _PlaceBidScreenState();
}

class _PlaceBidScreenState extends State<PlaceBidScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _bidController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _auctionTitle = 'title';
  String _auctionDescription = 'description';
  String _auctionImageUrl = 'image';
  DateTime _auctionEndingDate = DateTime.now();
  double _currentBasePrice = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchAuctionDetails();
    _fetchCurrentBasePrice();
  }

  void _fetchAuctionDetails() async {
    DocumentSnapshot auctionSnapshot = await FirebaseFirestore.instance
        .collection('Auctions')
        .doc(widget.auctionId)
        .get();

    if (auctionSnapshot.exists) {
      setState(() {
        _auctionTitle = auctionSnapshot['title'];
        _auctionDescription = auctionSnapshot['description'];
        _auctionImageUrl = auctionSnapshot['image'];
        _auctionEndingDate = auctionSnapshot['endingDate'].toDate();
      });
    }
  }

  void _fetchCurrentBasePrice() async {
    DocumentSnapshot auctionSnapshot = await FirebaseFirestore.instance
        .collection('Auctions')
        .doc(widget.auctionId)
        .get();

    if (auctionSnapshot.exists) {
      setState(() {
        _currentBasePrice = auctionSnapshot['basePrice'] ?? 0.0;
      });
    }
  }

  Future<String> _getUsername(String userId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (userSnapshot.exists) {
      return userSnapshot['username'];
    } else {
      return 'Anonymous';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Place a Bid'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: ListView(
          children: [
            // Display auction image
            Container(
              height: 200, // Set a fixed height for the image
              width: double.infinity,
              child: Image.network(_auctionImageUrl, fit: BoxFit.cover),
            ),

            // Display auction title
            Text(
              _auctionTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            // Display auction description
            Text(_auctionDescription),

            // Display auction ending date
            Text(
              'Ending Date: ${_auctionEndingDate.toString()}',
              style: TextStyle(fontSize: 18),
            ),

            // Display current base price
            Text(
              'Current Base Price: \$${_currentBasePrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),
            TextField(
              controller: _bidController,
              decoration: InputDecoration(
                labelText: 'Enter your bid',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _placeBid,
              child: Text('Place Bid'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Enter your comment',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _postComment,
              child: Text('Post Comment'),
            ),
            SizedBox(height: 20),
            Text(
              'Recent Bids and Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  // .collection('Auctions')
                  // .doc(widget.auctionId)
                  .collection('bids_and_comments')
                  .where('auctionId', isEqualTo: widget.auctionId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var items = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true, // Add this line
                  physics: NeverScrollableScrollPhysics(), // Add this line
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];
                    return ListTile(
                      title: Text(item['user']),
                      subtitle: Text(item['type'] == 'bid'
                          ? 'Bid: \$${item['price'].toStringAsFixed(2)}'
                          : 'Comment: ${item['text']}'),
                      trailing: Text(item['timestamp']!= null
                          ? item['timestamp'].toDate().toString()
                          : 'No timestamp'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeBid() async {
    double bidPrice = double.tryParse(_bidController.text)?? 0.0;
    if (bidPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a valid bid amount.'),
      ));
      return;
    }

    String userId = _auth.currentUser!.uid;
    String userName = await _getUsername(userId);

    await FirebaseFirestore.instance
        // .collection('Auctions')
        // .doc(widget.auctionId)
        .collection('bids_and_comments')
        .add({
      'userId': userId,
      'user': userName,
      'type': 'bid',
      'auctionId': widget.auctionId,
      'price': bidPrice,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update the base price of the auction
    double newBasePrice = _currentBasePrice + bidPrice;
    await FirebaseFirestore.instance
        .collection('Auctions')
        .doc(widget.auctionId)
        .update({'basePrice': newBasePrice});

    // Clear the text field
    _bidController.clear();

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Bid placed successfully.'),
    ));

    setState(() {
      _currentBasePrice = newBasePrice;
    });
  }

  Future<void> _postComment() async {
    String commentText = _commentController.text;
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a comment.'),
      ));
      return;
    }

    String userId = _auth.currentUser!.uid;
    String userName = await _getUsername(userId);

    await FirebaseFirestore.instance
        // .collection('Auctions')
        // .doc(widget.auctionId)
        .collection('bids_and_comments')
        .add({
      'userId': userId,
      'user': userName,
      'type': 'comment',
      'text': commentText,
      'auctionId': widget.auctionId,
      'timestamp': FieldValue.serverTimestamp(),

    });

    // Clear the text field
    _commentController.clear();

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Comment posted successfully.'),
    ));
  }
}