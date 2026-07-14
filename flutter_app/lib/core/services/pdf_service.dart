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
  // Note: This requires each PDF to be converted to images first,
  // then those images are combined into a new PDF.
  // For native PDF merging, consider using syncfusion_flutter_pdf package.
  Future<Uint8List> mergePdfs(List<String> pdfPaths) async {
    final output = pw.Document();
    final tempFiles = <File>[];

    try {
      for (final path in pdfPaths) {
        final file = File(path);
        if (!await file.exists()) continue;

        // Convert PDF to images using printing package
        final pdfBytes = await file.readAsBytes();
        final pages = await Printing.raster(
          pdfBytes,
          dpi: 200,
        ).toList();

        // Add each page as an image
        for (final page in pages) {
          final tempFile = File('${Directory.systemTemp.path}/pdf_page_${DateTime.now().microsecondsSinceEpoch}.png');
          await tempFile.writeAsBytes(await page.toPng());
          tempFiles.add(tempFile);

          final imageBytes = await tempFile.readAsBytes();
          output.addPage(
            pw.Page(
              build: (context) {
                return pw.Center(
                  child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
                );
              },
            ),
          );
        }
      }

      return await output.save();
    } finally {
      // Clean up temp files
      for (final file in tempFiles) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  // Split PDF: extract specified pages into separate PDFs
  // Note: This converts the PDF to images, then creates new PDFs for each requested page.
  // For native PDF splitting, consider using syncfusion_flutter_pdf package.
  Future<List<Uint8List>> splitPdf(
    String pdfPath,
    List<int> pageNumbers,
  ) async {
    final results = <Uint8List>[];
    final file = File(pdfPath);
    final pdfBytes = await file.readAsBytes();

    try {
      // Convert PDF to images
      final pages = await Printing.raster(pdfBytes, dpi: 200).toList();

      // Create a separate PDF for each requested page
      for (final pageNum in pageNumbers) {
        if (pageNum < 0 || pageNum >= pages.length) continue;

        final page = pages[pageNum];
        final tempFile = File('${Directory.systemTemp.path}/pdf_page_${DateTime.now().microsecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(await page.toPng());

        final singlePdf = pw.Document();
        final imageBytes = await tempFile.readAsBytes();

        singlePdf.addPage(
          pw.Page(
            build: (context) {
              return pw.Center(
                child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
              );
            },
          ),
        );

        results.add(await singlePdf.save());
        await tempFile.delete();
      }

      return results;
    } catch (e) {
      throw Exception('PDF splitting failed: $e');
    }
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
