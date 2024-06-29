import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tradehub/AuctionList.dart';
import 'package:tradehub/UserOwnAuctionItems.dart';

class ItemsByCurrentUser extends StatefulWidget {
  @override
  _ItemsByCurrentUserState createState() => _ItemsByCurrentUserState();
}

class _ItemsByCurrentUserState extends State<ItemsByCurrentUser> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _items = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() async {
    final User? user = _auth.currentUser;
    setState(() {
      _currentUserId = user?.uid;
    });
    _fetchUserItems();
  }

  void _fetchUserItems() async {
    if (_currentUserId != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('user')
          .where('uploaderId', isEqualTo: _currentUserId)
          .get();

      setState(() {
        _items = querySnapshot.docs;
      });

      for (var item in _items) {
        print('Item ID: ${item.id}, Image URL: ${item['image']}');
      }
    }
  }

  Future<int> _fetchRequestCount(String itemId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .get();

    return querySnapshot.size; // Number of requests for this item
  }

  void _deleteItem(String itemId) async {
    await _firestore.collection('user').doc(itemId).delete();
    _fetchUserItems(); // Refresh the item list
  }

  Widget tryLoadImage(String imageUrl) {
    if (Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false) {
      return Image.file(File(imageUrl));
    } else {
      return Icon(Icons.image, size: 100, color: Colors.grey);
    }
  }

  Widget _buildItemCard(DocumentSnapshot item) {
    var data = item.data() as Map<String, dynamic>;
    String imageUrl = data['image'] ?? '';
    String status = data['status'] ?? ''; // Add this line to retrieve the status field

    return FutureBuilder<int>(
      future: _fetchRequestCount(item.id),
      builder: (context, snapshot) {
        int requestCount = snapshot.data ?? 0; // Default to 0 if data is null

        return Card(
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
                    child: tryLoadImage(imageUrl),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'No Title',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      data['description'] ?? 'No Description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text('Requests: ${snapshot.data ?? 0}'), // Display the number of requests
                    SizedBox(height: 4),
                    Text('Status: $status'), // Add this line to display the status field
                    SizedBox(height: 8),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteItem(item.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () {
        //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MyAuctionsScreen()));
        // } ,),
        title: Text('My Items'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _items.isEmpty
          ? Center(child: Text('No items found'))
          : GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return _buildItemCard(_items[index]);
        },
      ),
    );
  }
}