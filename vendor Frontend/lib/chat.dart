import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatPage extends StatefulWidget {
  final int vendorId;
  final int customerId;

  ChatPage({required this.vendorId, required this.customerId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController msg = TextEditingController();
  List messages = [];

  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    connectSocket();
    loadMessages();
  }

  void connectSocket() {
    socket = IO.io(
      "http://10.0.2.2:5000",
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print("Connected");
    });

    socket.on("receive_message", (data) {
      setState(() {
        messages.add(data);
      });
    });
  }

  Future loadMessages() async {
    final res = await http.get(
      Uri.parse(
        "http://10.0.2.2:5000/messages/${widget.customerId}/${widget.vendorId}",
      ),
    );

    setState(() {
      messages = jsonDecode(res.body);
    });
  }

  void sendMessage() {
    if (msg.text.isEmpty) return;

    var data = {
      "customer_id": widget.customerId,
      "vendor_id": widget.vendorId,
      "sender": "customer",
      "message": msg.text,
    };

    socket.emit("send_message", data);

    msg.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vendor Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool mine = messages[index]["sender"] == "customer";

                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,

                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: mine ? Colors.pink : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      messages[index]["message"],
                      style: TextStyle(
                        color: mine ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: msg,
                  decoration: InputDecoration(hintText: "Message..."),
                ),
              ),

              IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
            ],
          ),
        ],
      ),
    );
  }
}
