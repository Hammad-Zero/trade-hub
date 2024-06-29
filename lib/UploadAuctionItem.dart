import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tradehub/AuctionList.dart';

class UploadAuctionScreen extends StatefulWidget {
  @override
  _UploadAuctionScreenState createState() => _UploadAuctionScreenState();
}

class _UploadAuctionScreenState extends State<UploadAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _basePriceController = TextEditingController();
  File? _image;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Auction'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _startDateController,
                decoration: InputDecoration(labelText: 'Start Date'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a start date';
                  }
                  return null;
                },
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDateController.text = picked.toString().split(' ').first;
                    });
                  }
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _endDateController,
                decoration: InputDecoration(labelText: 'End Date'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an end date';
                  }
                  return null;
                },
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _endDateController.text = picked.toString().split(' ').first;
                    });
                  }
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _basePriceController,
                decoration: InputDecoration(labelText: 'Base Price'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a base price';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Center(
                child: _image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    _image!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                )
                    : Text('No image selected'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  setState(() {
                    if (pickedFile != null) {
                      _image = File(pickedFile.path);
                    } else {
                      _image = null;
                    }
                  });
                },
                child: Text('Select Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && _image != null) {
                    await createAuction();
                  }
                },
                child: Text('Create Auction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> createAuction() async {
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child('auctions/${_titleController.text}/image');
    await imageRef.putFile(_image!);

    final auctionRef = FirebaseFirestore.instance.collection('Auctions').doc(); // Generate a unique ID
    final auctionId = auctionRef.id; // Get the generated ID

    final user = _auth.currentUser;
    if (user != null) {
      await auctionRef.set({
        'auctionId': auctionId, // Add the auctionId field
        'title': _titleController.text,
        'description': _descriptionController.text,
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'basePrice': double.parse(_basePriceController.text),
        'image': await imageRef.getDownloadURL(),
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(), // Firestore server timestamp
      });
    }

    // Show alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Auction Listed'),
          content: Text('Your auction has been listed. Check it out!'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AuctionsListScreen()), // Replace with your actual screen
                );
              },
            ),
          ],
        );
      },
    );
  }
}
