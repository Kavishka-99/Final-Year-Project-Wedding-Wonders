import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class MyWorksPage extends StatefulWidget {
  final int vendorId;

  const MyWorksPage({required this.vendorId});

  @override
  _MyWorksPageState createState() => _MyWorksPageState();
}

class _MyWorksPageState extends State<MyWorksPage> {
  List services = [];

  final String baseUrl = "http://localhost:3000/api/services";

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  // ✅ FETCH SERVICES
  Future<void> fetchServices() async {
    final res = await http.get(Uri.parse("$baseUrl/vendor/${widget.vendorId}"));

    if (res.statusCode == 200) {
      setState(() {
        services = jsonDecode(res.body);
      });
    }
  }

  // ✅ DELETE
  Future<void> deleteService(int id) async {
    await http.delete(Uri.parse("$baseUrl/$id"));
    fetchServices();
  }

  // ✅ SHARE
  void shareService(service) {
    Share.share(
      "${service['name']}\n${service['description']}\nPrice: Rs ${service['price']}",
    );
  }

  // ✅ UPDATE POPUP
  void showEditDialog(service) {
    TextEditingController name = TextEditingController(text: service['name']);
    TextEditingController desc = TextEditingController(
      text: service['description'],
    );
    TextEditingController price = TextEditingController(
      text: service['price'].toString(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Update Service"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: desc,
              decoration: InputDecoration(labelText: "Description"),
            ),
            TextField(
              controller: price,
              decoration: InputDecoration(labelText: "Price"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await http.put(
                Uri.parse("$baseUrl/${service['id']}"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "name": name.text,
                  "description": desc.text,
                  "price": price.text,
                }),
              );

              Navigator.pop(context);
              fetchServices();
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  // ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Works"), backgroundColor: Colors.red),
      body: services.isEmpty
          ? Center(child: Text("No Services Found"))
          : ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final s = services[index];

                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(s['name']),
                    subtitle: Text(s['description']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => showEditDialog(s),
                        ),

                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteService(s['id']),
                        ),

                        IconButton(
                          icon: Icon(Icons.share, color: Colors.green),
                          onPressed: () => shareService(s),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
