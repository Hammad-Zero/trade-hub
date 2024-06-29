import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfessionalOrderList extends StatelessWidget {
  final String status;

  ProfessionalOrderList({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(status)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('professionalId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .where('status', isEqualTo: status)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final List<DocumentSnapshot>? orders = snapshot.data?.docs;

          if (orders == null || orders.isEmpty) {
            // Handle the case where there's no data
            return Center(child: Text('No $status orders'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 4,
                child: ListTile(
                  title: Text('Order #${orders[index].id}'),
                  subtitle: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('Customer: ${order['userName']}'),
                      Text('Phone number: ${order['phoneNumber']}'),
                      Text('Price : ${order['price']}'),
                      Text('your Service: ${order['title']}'),
                      SizedBox(
                          height:8.0
                      ),
                      Text('Your order current status is ${order['status']}.'),
                      SizedBox(
                          height:8.0
                      ),
                      Row(
                          children:[
                            Text("change Order Status here  : "),
                            if (status == 'Accepted')
                              ElevatedButton(
                                onPressed: () => _progressOrder(orders[index].id),
                                child: Text('In Progress'),
                              ),
                            if (status == 'In Progress')
                              ElevatedButton(
                                onPressed: () => _completeOrder(orders[index].id),
                                child: Text('Completed'),
                              ),

                          ]
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

  void _progressOrder(String orderId) {
    // Update order status to 'Accepted' in Firestore
    updateOrderStatus(orderId, 'In Progress');
  }

  void _completeOrder(String orderId) {
    // Update order status to 'Rejected' in Firestore
    updateOrderStatus(orderId, 'Completed');
  }

  // Example of how to change order status in Firestore
  void updateOrderStatus(String orderId, String newStatus) {
    try {
      FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
    } catch (error) {
      print('Error updating order status: $error');
    }
  }
}