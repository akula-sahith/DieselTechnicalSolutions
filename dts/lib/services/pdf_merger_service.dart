import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/purchase_bill_model.dart';

final pdfMergerServiceProvider = Provider<PdfMergerService>((ref) {
  return PdfMergerService();
});

class PdfMergerService {
  /// Merges multiple local image files into a single PDF file and returns the File.
  Future<File> mergeImageFilesToPdf(List<File> imageFiles) async {
    final pdf = pw.Document();
    int pageCount = 0;

    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      if (!await file.exists()) continue;

      try {
        final bytes = await file.readAsBytes();
        final image = pw.MemoryImage(bytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(16),
            build: (pw.Context context) {
              return pw.Column(
                children: [
                  if (imageFiles.length > 1)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Page ${i + 1} of ${imageFiles.length}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Image(image, fit: pw.BoxFit.contain),
                    ),
                  ),
                ],
              );
            },
          ),
        );
        pageCount++;
      } catch (_) {
        // Skip unparseable images gracefully
      }
    }

    if (pageCount == 0) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Text('No valid image attachments found.'),
          ),
        ),
      );
    }

    final tempDir = await getTemporaryDirectory();
    final pdfFile = File(
      '${tempDir.path}/purchase_bill_merged_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final bytes = await pdf.save();
    await pdfFile.writeAsBytes(bytes);

    return pdfFile;
  }

  /// Downloads/loads network image bytes from a URL using Dio.
  Future<pw.MemoryImage?> _loadNetworkImage(String url) async {
    if (url.isEmpty) return null;
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        return pw.MemoryImage(Uint8List.fromList(response.data!));
      }
    } catch (_) {}
    return null;
  }

  /// Compiles multiple selected purchase bills into a single consolidated PDF document.
  Future<Uint8List> mergePurchaseBillsToPdf(List<PurchaseBillModel> bills) async {
    final pdf = pw.Document();

    // Load DTS Logo from Assets if available
    pw.ImageProvider? logoImage;
    try {
      final logoBytes = (await rootBundle.load('assets/images/logo.png'))
          .buffer
          .asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (_) {}

    // Calculate Totals
    final totalBillAmount =
        bills.fold<double>(0.0, (sum, bill) => sum + bill.amount);
    final totalTaxAmount =
        bills.fold<double>(0.0, (sum, bill) => sum + bill.taxAmount);

    // Page 1: Purchase Bills Summary Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 140,
                      height: 45,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Text(
                      'DTS',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0B2545'),
                      ),
                    ),
                  pw.Spacer(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'DIESEL TECHNICAL SOLUTIONS',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#0B2545'),
                        ),
                      ),
                      pw.Text(
                        'PURCHASE BILLS / TAX INVOICES STATEMENT',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#134074'),
                        ),
                      ),
                      pw.Text(
                        'Generated Date: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#0B2545')),
              pw.SizedBox(height: 10),

              // Summary Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F0F4F8'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                    color: PdfColor.fromHex('#0B2545'),
                    width: 0.5,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Bills Selected: ${bills.length}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9.5,
                        color: PdfColor.fromHex('#0B2545'),
                      ),
                    ),
                    pw.Text(
                      'Total GST Tax: RS ${totalTaxAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9.5,
                        color: PdfColor.fromHex('#0B2545'),
                      ),
                    ),
                    pw.Text(
                      'Total Amount: RS ${totalBillAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10.5,
                        color: PdfColor.fromHex('#0B2545'),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Summary Table
              pw.Text(
                'Bills Summary Breakdown',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0B2545'),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.8),
                  1: pw.FlexColumnWidth(2.5),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                  4: pw.FlexColumnWidth(1.5),
                  5: pw.FlexColumnWidth(2),
                  6: pw.FlexColumnWidth(2.5),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration:
                        pw.BoxDecoration(color: PdfColor.fromHex('#0B2545')),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('#',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Vendor Name',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Bill No.',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Date',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Status',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('GST Tax',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Total Amount',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8.5)),
                      ),
                    ],
                  ),
                  // Rows
                  ...List.generate(bills.length, (idx) {
                    final b = bills[idx];
                    final billNo = (b.billNumber != null && b.billNumber!.isNotEmpty) ? b.billNumber! : '-';

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx % 2 == 0
                            ? PdfColors.white
                            : PdfColor.fromHex('#F9FAFB'),
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${idx + 1}',
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(b.vendorName,
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(billNo,
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                              DateFormat('dd-MM-yyyy').format(b.billDate),
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(b.status.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 7.5,
                                fontWeight: pw.FontWeight.bold,
                                color: b.status.toLowerCase() == 'paid'
                                    ? PdfColors.green700
                                    : PdfColors.orange700,
                              )),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('RS ${b.taxAmount.toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('RS ${b.amount.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Load attachment images for each bill and append pages
    for (int i = 0; i < bills.length; i++) {
      final bill = bills[i];
      if (bill.attachmentUrl.isEmpty) continue;

      pw.MemoryImage? billImage;
      if (bill.attachmentUrl.startsWith('http')) {
        billImage = await _loadNetworkImage(bill.attachmentUrl);
      } else {
        final f = File(bill.attachmentUrl);
        if (await f.exists()) {
          try {
            billImage = pw.MemoryImage(await f.readAsBytes());
          } catch (_) {}
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Banner for this bill
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#0B2545'),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Bill ${i + 1} of ${bills.length}: ${bill.vendorName}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'Amount: RS ${bill.amount.toStringAsFixed(2)} | Date: ${DateFormat('dd-MM-yyyy').format(bill.billDate)}',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Bill photo image or placeholder
                pw.Expanded(
                  child: billImage != null
                      ? pw.Center(
                          child: pw.Image(billImage, fit: pw.BoxFit.contain),
                        )
                      : pw.Center(
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                'Attachment: ${bill.attachmentUrl}',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                '(Attachment available via URL)',
                                style: const pw.TextStyle(
                                    fontSize: 9, color: PdfColors.grey700),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Open print/save dialog for the merged PDF bytes
  Future<void> printOrSaveMergedPdf(
      Uint8List pdfBytes, String documentTitle) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: documentTitle,
    );
  }

  /// Share the merged PDF file via share dialog
  Future<void> shareMergedPdf(Uint8List pdfBytes, String documentTitle) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$documentTitle.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Merged Purchase Bills / Tax Invoices Document',
    );
  }
}
