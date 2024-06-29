import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class ShowPostsScreen extends StatefulWidget {
  final String userId;

  ShowPostsScreen({required this.userId});

  @override
  _ShowPostsScreenState createState() => _ShowPostsScreenState();
}

class _ShowPostsScreenState extends State<ShowPostsScreen> {
  Future<String> getFirebaseImageUrl(String imagePath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(imagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting image URL: $e');
      return '';
    }
  }

  Widget _loadImage(String imagePath) {
    if (imagePath.isNotEmpty) {
      if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
        return CachedNetworkImage(
          imageUrl: imagePath,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Icon(Icons.error),
        );
      } else if (imagePath.startsWith('/data')) {
        return Image.file(
          File(imagePath),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        return FutureBuilder(
          future: getFirebaseImageUrl(imagePath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Icon(Icons.error);
            }
            return CachedNetworkImage(
              imageUrl: snapshot.data!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            );
          },
        );
      }
    } else {
      return Icon(Icons.image_not_supported);
    }
  }

  Future<void> _approveItem(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('user').doc(docId).update({'status': 'approved'});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item approved successfully')),
      );
      // Remove the approved item from the screen
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve item: $e')),
      );
    }
  }

  Future<void> _deleteItem(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('user').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item deleted successfully')),
      );
      // Remove the deleted item from the screen
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Items'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('user').where('uploaderId', isEqualTo: widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          List<DocumentSnapshot> itemDocs = snapshot.data?.docs ?? [];

          if (itemDocs.isEmpty) {
            return Center(child: Text('No items found for this user.'));
          }

          return ListView.builder(
            itemCount: itemDocs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot itemDoc = itemDocs[index];
              Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;

              String docId = itemDoc.id;
              String contactDetail = itemData['contactDetail'] ?? 'N/A';
              String description = itemData['description'] ?? 'No description';
              String desiredItem = itemData['desiredItem'] ?? 'N/A';
              String image = itemData['image'] ?? '';
              String status = itemData['status'] ?? 'N/A';
              String title = itemData['title'] ?? 'No Title';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      _loadImage(image),
                      SizedBox(height: 8),
                      Text('Description: $description', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Desired Item: $desiredItem', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Contact: $contactDetail', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Status: $status', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await _approveItem(docId);
                              setState(() {
                                itemDocs.removeAt(index); // Remove the approved item from the list
                              });
                            },
                            style: ElevatedButton.styleFrom(primary: Colors.green),
                            child: Text('Approve'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await _deleteItem(docId);
                              setState(() {
                                itemDocs.removeAt(index); // Remove the deleted item from the list
                              });
                            },
                            style: ElevatedButton.styleFrom(primary: Colors.red),
                            child: Text('Delete'),
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
