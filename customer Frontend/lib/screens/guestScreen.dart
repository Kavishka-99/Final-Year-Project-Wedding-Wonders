import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wedding_planning/screens/homeScreen.dart';

class Guest {
  String name;
  String email;
  String whatsapp;
  bool isInvited;

  Guest({
    required this.name,
    required this.email,
    required this.whatsapp,
    this.isInvited = false,
  });
}

class GuestManagementScreen extends StatefulWidget {
  const GuestManagementScreen({super.key});

  @override
  State<GuestManagementScreen> createState() => _GuestManagementScreenState();
}

class _GuestManagementScreenState extends State<GuestManagementScreen> {
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _whatsappController = TextEditingController();

  String _selectedPrefix = 'Mr.';

  final List<String> _prefixes = ['Mr.', 'Mrs.', 'Miss'];

  final List<Guest> _guests = [];

  // ===========================
  // ADD GUEST
  // ===========================
  void _addGuest() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _whatsappController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() {
      _guests.add(
        Guest(
          name: "$_selectedPrefix ${_nameController.text}",
          email: _emailController.text,
          whatsapp: _whatsappController.text,
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _whatsappController.clear();
    });
  }

  // ===========================
  // GENERATE PDF INVITATION
  // ===========================
  Future<File> _generateInvitationPDF(String guestName, String date) async {
    final pdf = pw.Document();

    // Background image
    final Uint8List bgImage =
        (await rootBundle.load(
          'assets/images/invitation_bg.jpg',
        )).buffer.asUint8List();

    // QR code
    final qrCode = Barcode.qrCode();

    final qrSvg = qrCode.toSvg(
      'https://maps.google.com',
      width: 120,
      height: 120,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Background Image
              pw.Positioned.fill(
                child: pw.Image(pw.MemoryImage(bgImage), fit: pw.BoxFit.cover),
              ),

              // Main Content
              pw.Center(
                child: pw.Container(
                  margin: const pw.EdgeInsets.all(20),
                  padding: const pw.EdgeInsets.all(20),

                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xD9FFFFFF),
                    borderRadius: pw.BorderRadius.circular(16),
                  ),

                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,

                    children: [
                      pw.Text(
                        "💒 Wedding Invitation 💒",
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.pink800,
                        ),
                      ),

                      pw.SizedBox(height: 30),

                      pw.Text(
                        "Dear $guestName,",
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                      pw.SizedBox(height: 20),

                      pw.Text(
                        "We are delighted to invite you to celebrate our wedding day with us.",
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 16),
                      ),

                      pw.SizedBox(height: 25),

                      pw.Text(
                        "📅 Date: $date",
                        style: const pw.TextStyle(fontSize: 16),
                      ),

                      pw.SizedBox(height: 10),

                      pw.Text(
                        "📍 Venue: The Grand Garden Hall\nColombo, Sri Lanka",
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 15),
                      ),

                      pw.SizedBox(height: 25),

                      pw.Text(
                        "We look forward to celebrating with you ❤️",
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 15,
                          color: PdfColors.pink800,
                        ),
                      ),

                      pw.SizedBox(height: 35),

                      pw.Text(
                        "Scan QR for Venue",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),

                      pw.SizedBox(height: 10),

                      pw.SvgImage(svg: qrSvg),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();

    final file = File(
      "${output.path}/invitation_${guestName.replaceAll(" ", "_")}.pdf",
    );

    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // ===========================
  // SHARE OPTIONS
  // ===========================
  void _shareGuest(Guest guest, int index) {
    showModalBottomSheet(
      context: context,

      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              // =====================
              // PDF SHARE
              // =====================
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),

                title: const Text("Share Invitation PDF"),

                onTap: () async {
                  final file = await _generateInvitationPDF(
                    guest.name,
                    "15th December 2025",
                  );

                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text:
                        "Dear ${guest.name}, You are invited to our wedding 💍",
                  );

                  setState(() {
                    _guests[index].isInvited = true;
                  });

                  Navigator.pop(context);
                },
              ),

              // =====================
              // WHATSAPP SHARE
              // =====================
              ListTile(
                leading: const Icon(Icons.message, color: Colors.green),

                title: const Text("Send via WhatsApp"),

                onTap: () async {
                  String phone = guest.whatsapp.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );

                  // Convert to Sri Lanka format
                  if (!phone.startsWith("94")) {
                    if (phone.startsWith("0")) {
                      phone = "94${phone.substring(1)}";
                    } else {
                      phone = "94$phone";
                    }
                  }

                  final message = Uri.encodeComponent(
                    "Dear ${guest.name},\n\n"
                    "We are delighted to invite you to our wedding celebration 💒\n\n"
                    "📅 Date: 15th December 2025\n"
                    "📍 Venue: The Grand Garden Hall, Colombo\n\n"
                    "We would love to celebrate this special day with you ❤️",
                  );

                  final whatsappUrl = Uri.parse(
                    "https://wa.me/$phone?text=$message",
                  );

                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(
                      whatsappUrl,
                      mode: LaunchMode.externalApplication,
                    );

                    setState(() {
                      _guests[index].isInvited = true;
                    });
                  }

                  Navigator.pop(context);
                },
              ),

              // =====================
              // EMAIL SHARE
              // =====================
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),

                title: const Text("Send via Email"),

                onTap: () async {
                  final subject = Uri.encodeComponent("Wedding Invitation 💍");

                  final body = Uri.encodeComponent(
                    "Dear ${guest.name},\n\n"
                    "We are delighted to invite you to our wedding celebration.\n\n"
                    "📅 Date: 15th December 2025\n"
                    "📍 Venue: The Grand Garden Hall, Colombo\n\n"
                    "We would be honored to have your presence ❤️",
                  );

                  final emailUrl = Uri.parse(
                    "mailto:${guest.email}?subject=$subject&body=$body",
                  );

                  if (await canLaunchUrl(emailUrl)) {
                    await launchUrl(emailUrl);

                    setState(() {
                      _guests[index].isInvited = true;
                    });
                  }

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================
  // EDIT GUEST
  // ===========================
  void _editGuest(Guest guest, int index) {
    final TextEditingController editName = TextEditingController(
      text: guest.name,
    );

    final TextEditingController editEmail = TextEditingController(
      text: guest.email,
    );

    final TextEditingController editWhatsapp = TextEditingController(
      text: guest.whatsapp,
    );

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Guest"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                TextField(
                  controller: editName,
                  decoration: const InputDecoration(labelText: "Name"),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: editEmail,
                  decoration: const InputDecoration(labelText: "Email"),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: editWhatsapp,
                  decoration: const InputDecoration(
                    labelText: "WhatsApp Number",
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),

              onPressed: () {
                setState(() {
                  _guests[index].name = editName.text;

                  _guests[index].email = editEmail.text;

                  _guests[index].whatsapp = editWhatsapp.text;
                });

                Navigator.pop(context);
              },

              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  // ===========================
  // DELETE GUEST
  // ===========================
  void _deleteGuest(int index) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Guest"),

          content: const Text("Are you sure you want to delete this guest?"),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

              onPressed: () {
                setState(() {
                  _guests.removeAt(index);
                });

                Navigator.pop(context);
              },

              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // ===========================
  // GUEST CARD
  // ===========================
  Widget _buildGuestCard(Guest guest, int index) {
    return Card(
      elevation: 3,

      margin: const EdgeInsets.symmetric(vertical: 6),

      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: guest.isInvited ? Colors.green : Colors.grey,

          child: const Icon(Icons.person, color: Colors.white),
        ),

        title: Text(
          guest.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 5),

            Text("Email: ${guest.email}"),

            Text("WhatsApp: ${guest.whatsapp}"),

            const SizedBox(height: 5),

            Text(
              guest.isInvited ? "Invited" : "Will Invite",

              style: TextStyle(
                color: guest.isInvited ? Colors.green : Colors.orange,

                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.teal),

              onPressed: () {
                _shareGuest(guest, index);
              },
            ),

            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),

              onPressed: () {
                _editGuest(guest, index);
              },
            ),

            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),

              onPressed: () {
                _deleteGuest(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================
  // UI
  // ===========================
  @override
  Widget build(BuildContext context) {
    final willInvite = _guests.where((g) => !g.isInvited).toList();

    final invited = _guests.where((g) => g.isInvited).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        title: const Text("Guest Management"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // ===================
            // INPUT SECTION
            // ===================
            Card(
              elevation: 4,

              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  children: [
                    // Prefix + Name
                    Row(
                      children: [
                        Expanded(
                          flex: 2,

                          child: DropdownButtonFormField<String>(
                            value: _selectedPrefix,

                            decoration: const InputDecoration(
                              labelText: "Prefix",
                              border: OutlineInputBorder(),
                            ),

                            items:
                                _prefixes.map((prefix) {
                                  return DropdownMenuItem(
                                    value: prefix,
                                    child: Text(prefix),
                                  );
                                }).toList(),

                            onChanged: (value) {
                              setState(() {
                                _selectedPrefix = value!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          flex: 4,

                          child: TextField(
                            controller: _nameController,

                            decoration: const InputDecoration(
                              labelText: "Guest Name",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Email
                    TextField(
                      controller: _emailController,

                      keyboardType: TextInputType.emailAddress,

                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // WhatsApp
                    TextField(
                      controller: _whatsappController,

                      keyboardType: TextInputType.phone,

                      decoration: const InputDecoration(
                        labelText: "WhatsApp Number",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,

                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),

                        onPressed: _addGuest,

                        icon: const Icon(Icons.add),

                        label: const Text("Add Guest"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===================
            // GUEST LISTS
            // ===================
            Expanded(
              child: ListView(
                children: [
                  // Will Invite
                  const Text(
                    "Will Invite",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  ...willInvite.map((guest) {
                    return _buildGuestCard(guest, _guests.indexOf(guest));
                  }),

                  const SizedBox(height: 25),

                  // Invited
                  const Text(
                    "Invitees",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  ...invited.map((guest) {
                    return _buildGuestCard(guest, _guests.indexOf(guest));
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
