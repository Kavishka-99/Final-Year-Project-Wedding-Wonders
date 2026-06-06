import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddServiceScreen extends StatefulWidget {
  final int vendorId;

  const AddServiceScreen({required this.vendorId});

  @override
  _AddServiceScreenState createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '', description = '', category = 'Salon', location = '';
  double price = 0;
  DateTime? selectedDate;
  File? image;

  final List<String> categories = [
    'Salon',
    'Hotel',
    'Photography',
    'Decoration',
    'Music',
    'Transport',
  ];

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> submitService() async {
    if (!_formKey.currentState!.validate() ||
        image == null ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields and upload image")),
      );
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:3000/api/vendor/addService'),
    );
    request.fields['vendor_id'] = widget.vendorId.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['category'] = category;
    request.fields['location'] = location;
    request.fields['price'] = price.toString();
    request.fields['availability'] = jsonEncode([
      selectedDate!.toIso8601String(),
    ]);
    request.files.add(await http.MultipartFile.fromPath('image', image!.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Service Added Successfully")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $resBody")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Service")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Title"),
                onChanged: (val) => title = val,
                validator: (val) => val!.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Description"),
                onChanged: (val) => description = val,
                maxLines: 3,
              ),
              DropdownButtonFormField(
                value: category,
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => category = val as String),
                decoration: InputDecoration(labelText: "Category"),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Location"),
                onChanged: (val) => location = val,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Price (Rs)"),
                keyboardType: TextInputType.number,
                onChanged: (val) => price = double.tryParse(val) ?? 0,
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: Icon(Icons.image),
                label: Text("Upload Image"),
              ),
              if (image != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.file(image!, height: 100),
                ),
              ElevatedButton.icon(
                onPressed: pickDate,
                icon: Icon(Icons.calendar_today),
                label: Text("Select Availability"),
              ),
              if (selectedDate != null)
                Text(
                  "Available on: ${selectedDate!.toLocal().toShortString()}",
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitService,
                child: Text("Submit Service"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension DateFormatter on DateTime {
  String toShortString() =>
      "${this.year}-${this.month.toString().padLeft(2, '0')}-${this.day.toString().padLeft(2, '0')}";
}
