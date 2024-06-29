import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tradehub/AuctionList.dart';
import 'package:tradehub/ItemsbyCurrentUser.dart';
import 'package:tradehub/displaychat.dart';
import 'package:tradehub/profilescreen.dart';
import 'package:tradehub/requestlist.dart';
import 'package:tradehub/uploaditem.dart';
import 'Chat.dart';
import 'loginscreen.dart';
import 'notification.dart';
import 'request_screen.dart';

class ItemListScreen extends StatefulWidget {
  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _items = [];
  List<DocumentSnapshot> _filteredItems = [];
  int _selectedIndex = 2; // Default to "Explore" screen
  User? _currentUser;
  String? _currentUserId;
  String? _username; // Add a variable to store username

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _getCurrentUser();
    _addUploaderIdToExistingDocuments();
    _fetchUserData(); // Fetch user data when the screen initializes
  }

  void _getCurrentUser() async {
    _currentUser = _auth.currentUser;
    setState(() {
      _currentUserId = _currentUser?.uid;
    });
  }

  Future<void> _fetchUserData() async {
    final User? user = _auth.currentUser;
    final String? currentUserId = user?.uid;

    if (currentUserId != null) {
      DocumentSnapshot userData = await _firestore.collection('users').doc(currentUserId).get();
      setState(() {
        _username = userData.get('username');
      });
    }
  }

  void _fetchItems() async {
    QuerySnapshot querySnapshot = await _firestore.collection('user').where('status',isEqualTo:'approved' ).get();
    setState(() {
      _items = querySnapshot.docs;
      _filteredItems = _items;
    });
  }

  void _searchItems(String query) {
    setState(() {
      _filteredItems = _items
          .where((item) => item['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Widget tryLoadImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        placeholder: (context, url) => Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => Icon(Icons.error),
      );
    } else {
      return Image.file(File(imageUrl));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => UserListScreen()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => UploadItemScreen()));
        break;
      case 2:
      // Stay on Explore screen (current screen)
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => RequestListScreen()));
        break;
      case 4:
        // Navigator.push(context, MaterialPageRoute(builder: (context) => AllIAuctiontems()));
        break;
    }
  }

  // void _uploadItem() async {
  //   final User? user = _auth.currentUser;
  //   final String? currentUserId = user?.uid;
  //
  //   await _firestore.collection('user').add({
  //     'title': 'Item Title',
  //     'description': 'Item Description',
  //     'image': 'Item Image URL',
  //     'desiredItem': 'Desired Item',
  //     'uploaderId': currentUserId,
  //   });
  // }

  void _addUploaderIdToExistingDocuments() async {
    final User? user = _auth.currentUser;
    final String? currentUserId = user?.uid;

    QuerySnapshot querySnapshot = await _firestore.collection('user').get();

    WriteBatch batch = _firestore.batch();

    querySnapshot.docs.forEach((document) {
      final data = document.data() as Map<String, dynamic>?;
      if (data != null && !data.containsKey('uploaderId')) {
        batch.update(document.reference, {
          'uploaderId': currentUserId,
        });
      }
    });

    await batch.commit();
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exchange It'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
        ],
        automaticallyImplyLeading: true, // This removes the default back arrow
      ),
      drawer: Drawer(
        child: FutureBuilder<void>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Exchange it now !',
                        style: TextStyle(color: Colors.white, fontSize: 25,),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _username ?? 'Loading...', // Display username here
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text(
                    'Profile',
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    // Navigate to profile screen
                    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> AllIAuctiontems())); // Close the drawer
                  },
                ),
                ListTile(
                  leading: Icon(Icons.post_add),
                  title: Text(
                    'Your items',
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ItemsByCurrentUser()),
                  ) ,
                ),
                ListTile(
                  leading: Icon(Icons.post_add),
                  title: Text(
                    'Want Auction?',
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AuctionsListScreen()),
                  ) ,
                ),
                ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text(
                    'Logout',
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: _logout,
                ),

              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Items',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchItems,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                var item = _filteredItems[index];
                bool isUploader = item.get('uploaderId') == _currentUserId;

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                child: Container(
                                  width: double.infinity,
                                  height: 200,
                                  child: tryLoadImage(item['image']),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'],
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text('Description: ${item['description']}'),
                                    SizedBox(height: 8),
                                    Text('Desired Item: ${item['desiredItem']}'),
                                    SizedBox(height: 8),
                                    Text('Contact Detail: ${item['contactDetail']}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            child: Container(
                              width: double.infinity,
                              child: tryLoadImage(item['image']),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                item['description'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              isUploader
                                  ? IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  await _firestore.collection('user').doc(item.id).delete();
                                  _fetchItems();
                                },
                              )
                                  : ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RequestScreen(item: item),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Request',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.request_page), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        ],
      ),
    );
  }
}
