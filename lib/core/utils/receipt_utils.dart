import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/trip_model.dart';
import '../constants/app_strings.dart';

const _green = PdfColor.fromInt(0xFF1B5E20);
const _grey = PdfColor.fromInt(0xFF757575);

String buildShareText(TripModel trip) {
  return '''🧾 FareTrack BD - ভাড়ার রসিদ

🚌 ${AppStrings.fareLabel}: ${trip.formattedFare}
📏 ${AppStrings.distanceLabel}: ${trip.formattedDistance}
⏱ ${AppStrings.durationLabel}: ${trip.formattedDuration}
⚠️ ${AppStrings.jamTimeLabel}: ${trip.formattedJamTime}
⚡ ${AppStrings.avgSpeedLabel}: ${trip.formattedAverageSpeed}

📅 ${trip.formattedDate}
🕐 ${trip.formattedStartTime} - ${trip.formattedEndTime}

${AppStrings.tripComplete}!
FareTrack BD''' ;
}

Future<void> shareReceiptText(TripModel trip) async {
  final text = buildShareText(trip);
  await SharePlus.instance.share(
    ShareParams(text: text, subject: 'FareTrack BD - ${AppStrings.tripComplete}'),
  );
}

Future<File> generateReceiptPdf(TripModel trip) async {
  final pdf = pw.Document();

  final fontData = await rootBundle.load('assets/fonts/HindSiliguri-Regular.ttf');
  final boldFontData = await rootBundle.load('assets/fonts/HindSiliguri-Bold.ttf');
  final bengaliFont = pw.Font.ttf(fontData);
  final bengaliBold = pw.Font.ttf(boldFontData);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a6,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: pw.BoxDecoration(
              color: _green,
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'FareTrack BD',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    font: bengaliBold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  AppStrings.tripComplete,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                    font: bengaliFont,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            trip.formattedFare,
            style: pw.TextStyle(
              color: _green,
              fontSize: 40,
              fontWeight: pw.FontWeight.bold,
              font: bengaliBold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            AppStrings.fareLabel,
            style: pw.TextStyle(color: _grey, fontSize: 10, font: bengaliFont),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 12),
          _detailRow(trip.formattedDistance, AppStrings.distanceLabel, bengaliFont, bengaliBold),
          pw.SizedBox(height: 8),
          _detailRow(trip.formattedDuration, AppStrings.durationLabel, bengaliFont, bengaliBold),
          pw.SizedBox(height: 8),
          _detailRow(trip.formattedJamTime, AppStrings.jamTimeLabel, bengaliFont, bengaliBold),
          pw.SizedBox(height: 8),
          _detailRow(trip.formattedAverageSpeed, AppStrings.avgSpeedLabel, bengaliFont, bengaliBold),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 12),
          _infoRow(trip.formattedDate, trip.formattedStartTime, bengaliFont, bengaliBold),
          pw.SizedBox(height: 4),
          _infoRow('${AppStrings.durationLabel}: ${trip.formattedDuration}', trip.formattedEndTime, bengaliFont, bengaliBold),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              '${AppStrings.tripComplete}!',
              style: pw.TextStyle(color: PdfColors.grey500, fontSize: 9, font: bengaliFont),
            ),
          ),
        ],
      ),
    ),
  );

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/faretrack_${trip.id}.pdf');
  await file.writeAsBytes(await pdf.save());
  return file;
}

pw.Widget _infoRow(String label, String value, pw.Font font, pw.Font boldFont) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: pw.TextStyle(color: _grey, fontSize: 10, font: font)),
      pw.Text(value,
          style: pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
    ],
  );
}

pw.Widget _detailRow(String value, String label, pw.Font font, pw.Font boldFont) {
  return pw.Row(
    children: [
      pw.Text(label, style: pw.TextStyle(color: _grey, fontSize: 11, font: font)),
      pw.Spacer(),
      pw.Text(value,
          style: pw.TextStyle(
              fontSize: 11, fontWeight: pw.FontWeight.bold, font: boldFont)),
    ],
  );
}
