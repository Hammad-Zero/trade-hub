import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tradehub/PlaceBid.dart';
import 'package:tradehub/UploadAuctionItem.dart';
import 'package:tradehub/UserOwnAuctionItems.dart';
import 'package:tradehub/detaileditemsexchangescreen.dart';
import 'package:tradehub/profilescreen.dart';

class AuctionsListScreen extends StatefulWidget {
  @override
  _AuctionsListScreenState createState() => _AuctionsListScreenState();
}

class _AuctionsListScreenState extends State<AuctionsListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;

  final List<Widget> _screens = [
    AuctionsListScreen(), // Placeholder for current screen
    UploadAuctionScreen(),
    ItemListScreen(),
    MyAuctionsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate to the selected screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _screens[_currentIndex]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auctions'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, Auctioneer!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _auth.currentUser!.email!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                _onTabTapped(1); // Navigate to ProfileScreen
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () async {
                await _auth.signOut();
                Navigator.pop(context); // Close drawer
                Navigator.pop(context); // Navigate back to previous screen (login or home)
              },
            ),
            ListTile(
              leading: Icon(Icons.swap_horiz),
              title: Text('Want to Exchange?'),
              onTap: () {
                _onTabTapped(2); // Navigate to ItemListScreen
              },
            ),
            ListTile(
              leading: Icon(Icons.post_add),
              title: Text('Your Auctions'),
              onTap: () {
                _onTabTapped(3); // Navigate to MyAuctionsScreen
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Auctions')
            .where('userId', isNotEqualTo: _auth.currentUser!.uid)
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Auctions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Exchange',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'My Auctions',
          ),
        ],
      ),
    );
  }
}

class AuctionListItem extends StatelessWidget {
  final DocumentSnapshot auction;

  const AuctionListItem({required this.auction});

  @override
  Widget build(BuildContext context) {
    String title = auction['title'];
    String description = auction['description'];
    double basePrice = auction['basePrice'] ?? 0.0;
    String imageUrl = auction['image'];
    String auctionId = auction['auctionId'];
    DateTime endDate = DateTime.parse(auction['endDate']);
    Duration timeRemaining = endDate.difference(DateTime.now());

    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10),
                Text(
                  'Base Price: \$${basePrice.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time Left: ${timeRemaining.inHours}:${(timeRemaining.inMinutes % 60).toString().padLeft(2, '0')}:${(timeRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaceBidScreen(auctionId: auctionId),
                          ),
                        );
                      },
                      child: Text('Place a Bid'),
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
