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

  // Merge multiple PDFs (simplified - combines pages into new PDF)
  Future<Uint8List> mergePdfs(List<String> pdfPaths) async {
    // Note: Merging existing PDFs requires additional packages like syncfusion_flutter_pdf
    // For now, return empty document as placeholder
    final output = pw.Document();
    output.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text('PDF Merge not yet implemented'),
        ),
      ),
    );
    return await output.save();
  }

  // Split PDF (placeholder - requires additional PDF manipulation library)
  Future<List<Uint8List>> splitPdf(
    String pdfPath,
    List<int> pageNumbers,
  ) async {
    // TODO: Implement PDF splitting using syncfusion_flutter_pdf or similar
    throw UnimplementedError('PDF splitting is not yet implemented');
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
    // Implementation would use share_plus package
    // For now, just save to temp location
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfData);
  }
}
