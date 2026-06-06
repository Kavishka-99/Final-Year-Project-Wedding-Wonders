import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AiImagePage extends StatefulWidget {
  @override
  _AiImagePageState createState() => _AiImagePageState();
}

class _AiImagePageState extends State<AiImagePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _apiController = TextEditingController();
  String? imageUrl;
  bool loading = false;
  // Candidates for API base URL. generateImage will try them in order until
  // one responds. This covers AVD (10.0.2.2), Genymotion (10.0.3.2),
  // iOS simulator / desktop (localhost), and falls back to localhost.
  List<String> _candidateApiBases() {
    final List<String> list = [];
    if (kIsWeb) {
      list.add('http://localhost:5000');
      return list;
    }

    try {
      if (Platform.isAndroid) {
        list.add('http://10.0.2.2:5000'); // Android AVD
        list.add('http://10.0.3.2:5000'); // Genymotion
        list.add('http://localhost:5000');
      } else if (Platform.isIOS) {
        list.add('http://localhost:5000'); // iOS simulator
      } else {
        list.add('http://localhost:5000');
      }
    } catch (_) {
      list.add('http://localhost:5000');
    }

    return list;
  }

  String _normalizeBase(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }
    // remove trailing slash
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  Future<void> generateImage() async {
    if (mounted) setState(() => loading = true);
    try {
      final override = _apiController.text.trim();
      final List<String> candidates = [];

      if (override.isNotEmpty) {
        final norm = _normalizeBase(override);
        if (norm.isNotEmpty) candidates.add(norm);
      }

      if (candidates.isEmpty) {
        candidates.addAll(_candidateApiBases());
      }
      bool success = false;
      String? lastErrorMsg;

      for (final base in candidates) {
        try {
          final uri = Uri.parse('$base/api/ai-image');
          final response = await http.post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "user_id": 1,
              "prompt":
                  _controller.text.isNotEmpty
                      ? _controller.text
                      : "a 3D realistic wedding invitation",
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data != null && data['imageUrl'] != null) {
              if (mounted) {
                setState(() {
                  imageUrl = data['imageUrl'];
                });
              }
              success = true;
              break;
            } else {
              lastErrorMsg =
                  data != null && data['error'] != null
                      ? data['error'].toString()
                      : 'Unexpected response from server at $base';
              continue;
            }
          } else {
            // Capture server response body to help debugging 500 errors
            final body = response.body ?? '';
            lastErrorMsg =
                'Server error ${response.statusCode} at $base: $body';
            debugPrint(
              'AI image server error at $base: ${response.statusCode} -- $body',
            );
            continue;
          }
        } on SocketException catch (_) {
          lastErrorMsg = 'Network error connecting to $base';
          continue;
        }
      }

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not reach backend. ${lastErrorMsg ?? ''}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _apiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Image Generator")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _apiController,
              decoration: InputDecoration(
                labelText: "Server URL (optional)",
                hintText: "http://localhost:5000 or https://abcd.ngrok.io",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Enter prompt",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: generateImage,
              child: Text("Generate Image"),
            ),
            SizedBox(height: 20),
            if (loading) CircularProgressIndicator(),
            if (imageUrl != null) Expanded(child: Image.network(imageUrl!)),
          ],
        ),
      ),
    );
  }
}
