import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:wedding_planning/guestModel.dart/guestModel.dart';

Future<File> _generateInvitationPDF(Guest guest) async {
  final pdf = pw.Document();

  // ✅ Load image correctly
  final Uint8List imageBytes =
      (await rootBundle.load('assets/invitation.jpg')).buffer.asUint8List();
  final pw.ImageProvider imageProvider = pw.MemoryImage(imageBytes);

  // ✅ Create PDF Page
  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Image(imageProvider, fit: pw.BoxFit.cover),
            ),
            pw.Center(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'Wedding Invitation',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'Dear ${guest.name},',
                    style: pw.TextStyle(fontSize: 18, color: PdfColors.white),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'You are cordially invited to celebrate our wedding on',
                    style: pw.TextStyle(color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Saturday, 14 December 2025',
                    style: pw.TextStyle(
                      fontSize: 20,
                      color: PdfColors.amber,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'Venue: Sunset Gardens, Colombo',
                    style: pw.TextStyle(color: PdfColors.white),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // ✅ Save the file
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/${guest.name.replaceAll(" ", "_")}_invitation.pdf',
  );
  await file.writeAsBytes(await pdf.save());
  return file;
}
