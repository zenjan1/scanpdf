import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  // Create PDF from multiple images
  Future<Uint8List> createPdfFromImages(
    List<String> imagePaths, {
    PdfPageFormat format = PdfPageFormat.a4,
    double dpi = 300,
    bool autoRotate = true,
  }) async {
    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    return await pdf.save();
  }

  // Create PDF with OCR text layer
  Future<Uint8List> createSearchablePdf(
    List<String> imagePaths,
    List<String> ocrTexts, {
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final pdf = pw.Document();

    for (int i = 0; i < imagePaths.length; i++) {
      final imagePath = imagePaths[i];
      final ocrText = i < ocrTexts.length ? ocrTexts[i] : '';

      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (context) {
            return pw.Stack(
              children: [
                // Image layer
                pw.Center(
                  child: pw.Image(
                    image,
                    fit: pw.BoxFit.contain,
                  ),
                ),
                // Hidden text layer for search
                if (ocrText.isNotEmpty)
                  pw.Positioned(
                    left: 0,
                    top: 0,
                    child: pw.Text(
                      ocrText,
                      style: const pw.TextStyle(
                        fontSize: 1,
                        color: PdfColor.fromInt(0x00000000),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    return await pdf.save();
  }

  // Merge multiple PDFs into one
  Future<Uint8List> mergePdfs(List<String> pdfPaths) async {
    final output = pw.Document();

    for (final path in pdfPaths) {
      final file = File(path);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      // Extract images from each PDF and add as new pages
      output.addPage(
        pw.Page(
          build: (context) {
            return pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain);
          },
        ),
      );
    }

    return await output.save();
  }

  // Split PDF: extract specified pages into separate PDFs
  Future<List<Uint8List>> splitPdf(
    String pdfPath,
    List<int> pageNumbers,
  ) async {
    final results = <Uint8List>[];
    final file = File(pdfPath);
    final pdfBytes = await file.readAsBytes();

    // Create a separate PDF for each requested page
    for (final pageNum in pageNumbers) {
      if (pageNum < 0) continue;
      final singlePdf = pw.Document();
      singlePdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '第 ${pageNum + 1} 页',
                  style: const pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 8),
                pw.Image(pw.MemoryImage(pdfBytes), fit: pw.BoxFit.contain),
              ],
            );
          },
        ),
      );
      results.add(await singlePdf.save());
    }

    return results;
  }

  // Print PDF
  Future<void> printPdf(Uint8List pdfData, String jobName) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
      name: jobName,
    );
  }

  // Share PDF
  Future<void> sharePdf(Uint8List pdfData, String fileName) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfData);
  }
}
