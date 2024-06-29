import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tradehub/BidsandMessages.dart';

class MyAuctionsScreen extends StatefulWidget {
  @override
  _MyAuctionsScreenState createState() => _MyAuctionsScreenState();
}

class _MyAuctionsScreenState extends State<MyAuctionsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Auctions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Auctions')
            .where('userId', isEqualTo: _auth.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          List<DocumentSnapshot> auctions = snapshot.data!.docs;
          return ListView.builder(
            itemCount: auctions.length,
            itemBuilder: (context, index) {
              var auction = auctions[index];
              return AuctionListItem(auction: auction);
            },
          );
        },
      ),
    );
  }
}

class AuctionListItem extends StatelessWidget {
  final DocumentSnapshot auction;

  const AuctionListItem({required this.auction});

  Future<void> _deleteAuction(BuildContext context) async {
    await FirebaseFirestore.instance.collection('Auctions').doc(auction.id).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auction deleted')));
  }

  @override
  Widget build(BuildContext context) {
    String title = auction['title'];
    String description = auction['description'];
    double basePrice = auction['basePrice'] ?? 0.0;
    String imageUrl = auction['image'];
    String itemId=auction['auctionId'];
    String auctionId=auction['auctionId'];
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(description),
                SizedBox(height: 10),
                Text('Base Price: \$${basePrice.toStringAsFixed(2)}'),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Navigate to see bids screen
                        Example: Navigator.push(context, MaterialPageRoute(builder: (context) => BidsScreen(auctionId: auctionId)));
                      },
                      child: Text('See Bids'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Confirm Delete'),
                              content: Text('Are you sure you want to delete this auction?'),
                              actions: [
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(primary: Colors.red),
                                  child: Text('Delete'),
                                  onPressed: () {
                                    _deleteAuction(context);
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
