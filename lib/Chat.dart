
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';



class ChatScreen extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final String receiverName; // Receiver name

  ChatScreen({super.key, required this.senderId, required this.receiverId, required this.receiverName, });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool user=false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkuserexist();
  }
  void checkuserexist()
  async {
    DocumentSnapshot receiverSnapshot = await FirebaseFirestore.instance.collection('users').doc(widget.receiverId).get();
    if(receiverSnapshot.exists)
    {
      setState(() {
        user=true;
      });

    }
  }
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void sendMessage(String message) {
    if (message.isNotEmpty) {
      _firestore.collection('messages').add({
        'text': message,
        'sender': widget.senderId,
        'receiver': widget.receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'delivered',
      });
      _controller.clear();
    }
  }

  void markAsRead(DocumentSnapshot document) {
    if (document['status'] == 'delivered' && document['receiver'] == widget.senderId) {
      _firestore.collection('messages').doc(document.id).update({'status': 'read'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Row(
          children: [
            Text(widget.receiverName),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<List<QuerySnapshot>>(
              stream: CombineLatestStream.list([
                _firestore
                    .collection('messages')
                    .where('sender', isEqualTo: widget.senderId)
                    .where('receiver', isEqualTo: widget.receiverId)
                    .orderBy('timestamp') // Default is ascending order
                    .snapshots(),
                _firestore
                    .collection('messages')
                    .where('sender', isEqualTo: widget.receiverId)
                    .where('receiver', isEqualTo: widget.senderId)
                    .orderBy('timestamp') // Default is ascending order
                    .snapshots(),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final List<QueryDocumentSnapshot> messages = snapshot.data!
                    .expand((querySnapshot) => querySnapshot.docs)
                    .toList()
                  ..sort((a, b) {
                    Timestamp aTimestamp = a['timestamp'] ?? Timestamp.now();
                    Timestamp bTimestamp = b['timestamp'] ?? Timestamp.now();
                    return aTimestamp.compareTo(bTimestamp);
                  });

                List<Widget> messageWidgets = [];
                for (var message in messages) {
                  final messageText = message['text'];
                  final messageSender = message['sender'];
                  final messageReceiver = message['receiver'];
                  final messageStatus = message['status'];

                  final messageWidget = MessageBubble(
                    sender: messageSender,
                    text: messageText,
                    isMe: widget.senderId == messageSender,
                    status: messageStatus,
                  );

                  if (messageReceiver == widget.senderId) {
                    markAsRead(message);
                  }

                  messageWidgets.add(messageWidget);
                }

                return ListView(
                  children: messageWidgets,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    sendMessage(_controller.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  final String status;

  MessageBubble({required this.sender, required this.text, required this.isMe, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
              topLeft: Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
            )
                : BorderRadius.only(
              topRight: Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
            ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black54,
                      fontSize: 15.0,
                    ),
                  ),
                  if(isMe)
                    Text(
                      status == 'delivered' ? 'Delivered' : 'Read',
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.black38,
                        fontSize: 10.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}