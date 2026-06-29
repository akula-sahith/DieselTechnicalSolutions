import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';
import 'api_service.dart';

final pdfServiceProvider = Provider<PdfService>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return PdfService(baseUrl);
});

class PdfService {
  final String _apiBaseUrl;

  PdfService(this._apiBaseUrl);

  String _resolveUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    
    // Check if it is a local path (Windows drive path or Android app directory)
    bool isLocal = false;
    try {
      if (url.contains(':\\') || url.contains('/data/') || url.contains('cache') || url.contains('temp')) {
        isLocal = true;
      }
    } catch (_) {}
    
    if (isLocal) return url;
    
    // Extract base server URL (strip /api)
    String serverUrl = _apiBaseUrl;
    if (serverUrl.endsWith('/api')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 4);
    } else if (serverUrl.endsWith('/api/')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 5);
    }
    
    final path = url.startsWith('/') ? url : '/$url';
    return '$serverUrl$path';
  }

  Future<pw.ImageProvider?> _loadNetworkImage(String url) async {
    if (url.isEmpty) return null;
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        return pw.MemoryImage(Uint8List.fromList(response.data!));
      }
    } catch (e) {
      // Fail silently and return null to prevent freezing
    }
    return null;
  }

  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: PdfColor.fromHex('#0B2545'),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 11.0,
        ),
      ),
    );
  }

  pw.Widget _buildFormCell(String label, String value, {String unit = ''}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#0B2545'),
                fontSize: 9.5,
              ),
            ),
            pw.TextSpan(
              text: ' ${value.isNotEmpty ? value : ''}',
              style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
            ),
            if (unit.isNotEmpty)
              pw.TextSpan(
                text: ' $unit',
                style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600),
              ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> generatePdf(ReportModel report) async {
    final pdf = pw.Document();

    // 1. Load Logo from Assets
    pw.ImageProvider? logoImage;
    try {
      final logoBytes = (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      // Fallback
    }

    // 2. Load Network/Local Images for Signature and customer Photo
    pw.ImageProvider? signatureImage;
    pw.ImageProvider? customerPhoto;

    if (report.authorization.technicianSignatureUrl.isNotEmpty) {
      final resolvedUrl = _resolveUrl(report.authorization.technicianSignatureUrl);
      if (resolvedUrl.startsWith('http')) {
        signatureImage = await _loadNetworkImage(resolvedUrl);
      } else {
        // Local file path
        final file = File(resolvedUrl);
        if (await file.exists()) {
          try {
            signatureImage = pw.MemoryImage(await file.readAsBytes());
          } catch (e) {
            // Ignore
          }
        }
      }
    }

    if (report.authorization.customerPhotoUrl.isNotEmpty) {
      final resolvedUrl = _resolveUrl(report.authorization.customerPhotoUrl);
      if (resolvedUrl.startsWith('http')) {
        customerPhoto = await _loadNetworkImage(resolvedUrl);
      } else {
        // Local file path
        final file = File(resolvedUrl);
        if (await file.exists()) {
          try {
            customerPhoto = pw.MemoryImage(await file.readAsBytes());
          } catch (e) {
            // Ignore
          }
        }
      }
    }

    final normalFont = pw.Font.ttf(
  await rootBundle.load('assets/fonts/roboto1.ttf'),
);

final checkFont = pw.Font.ttf(
  await rootBundle.load('assets/fonts/checkicons.ttf'),
);

pw.Widget statusWidget(String status) {
  final lower = status.toLowerCase();

  pw.Widget item(String label, bool checked) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          checked ? 'O' : 'S', // O = checked, S = empty
          style: pw.TextStyle(
            font: checkFont,
            fontSize: 10,
          ),
        ),
        pw.SizedBox(width: 2),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: normalFont,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  return pw.Row(
    children: [
      item('OK', lower == 'ok'),
      pw.SizedBox(width: 8),
      item('Req', lower == 'req'),
      pw.SizedBox(width: 8),
      item('N/A', lower != 'ok' && lower != 'req'),
    ],
  );
}

    final parts = report.partsUsed;
    final partsRowsCount = (parts.length / 2).ceil();
    final partsTableRows = <pw.TableRow>[];
    
    // Subheader row
    partsTableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E0E7FF')),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pw.Text('Part Description / Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 9.5)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pw.Text('Qty / Ltr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 9.5)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pw.Text('Part Description / Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 9.5)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pw.Text('Qty / Ltr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 9.5)),
          ),
        ],
      ),
    );

    // Populate data
    for (int i = 0; i < partsRowsCount; i++) {
      final part1 = parts[i * 2];
      final part2 = (i * 2 + 1 < parts.length) ? parts[i * 2 + 1] : null;

      partsTableRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: pw.Text(part1.partDescription, style: const pw.TextStyle(fontSize: 9.5)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: pw.Text(part1.qty, style: const pw.TextStyle(fontSize: 9.5)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: pw.Text(part2?.partDescription ?? '', style: const pw.TextStyle(fontSize: 9.5)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: pw.Text(part2?.qty ?? '', style: const pw.TextStyle(fontSize: 9.5)),
            ),
          ],
        ),
      );
    }

    if (parts.isEmpty) {
      partsTableRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: pw.Text('', style: const pw.TextStyle(fontSize: 8.5)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: pw.Text('', style: const pw.TextStyle(fontSize: 8.5)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: pw.Text('', style: const pw.TextStyle(fontSize: 8.5)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: pw.Text('', style: const pw.TextStyle(fontSize: 8.5)),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // PDF Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Left logo
                  pw.Expanded(
                    flex: 2,
                    child: pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: logoImage != null
                          ? pw.Container(
                              width: 350,
                              height: 70,
                              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                            )
                          : pw.Text('DTS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'))),
                    ),
                  ),
                  
                  // Center details (Centred relative to its column area)
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'DIESEL TECHNICAL SOLUTIONS',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545')),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '2-2-128/G/100/1, PLOT NO 100\n Sai Baba Nagar Colony, Road No.1, Laxma Reddy Colony, Uppal, Hyderabad, Telangana\nTel: +91 81213 12253 | Email: dieseltechniaclsolutions@zohomail.in\nWeb: www.dieseltechnicalsolutions.com',
                          style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Right title
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'ELECTRONIC FIELD SERVICE REPORT (eFSR)',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545')),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          'GENERATOR MAINTENANCE & TECHNICAL INSPECTION RECORD',
                          style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#134074')),
                          textAlign: pw.TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1.0, color: PdfColor.fromHex('#0B2545')),
              pw.SizedBox(height: 10),

              // 1. SERVICE & CUSTOMER DETAILS
              _buildSectionHeader('1. SERVICE & CUSTOMER DETAILS'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    children: [
                      _buildFormCell('Job / Ticket Ref:', report.serviceAndCustomer.jobRef),
                      _buildFormCell('Date & Time:', DateFormat('dd-MM-yyyy HH:mm').format(report.serviceAndCustomer.dateTime)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildFormCell('Customer Name:', report.serviceAndCustomer.customerName),
                      _buildFormCell('Site ID / Location:', report.serviceAndCustomer.siteLocation),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildFormCell('Contact Person:', report.serviceAndCustomer.contactPerson),
                      _buildFormCell('Contact Number:', report.serviceAndCustomer.contactNumber),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // 2. EQUIPMENT & ENGINE DETAILS
              _buildSectionHeader('2. EQUIPMENT & ENGINE DETAILS'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    children: [
                      _buildFormCell('Generator Make/Model:', report.equipmentAndEngine.generatorMakeModel),
                      _buildFormCell('Capacity (kVA / kW):', report.equipmentAndEngine.capacity),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildFormCell('Engine Serial No:', report.equipmentAndEngine.engineSerialNo),
                      _buildFormCell('Alternator Serial No:', report.equipmentAndEngine.alternatorSerialNo),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildFormCell(
                        'Hour Meter (HMR):',
                        report.equipmentAndEngine.hourMeter.isNotEmpty 
                            ? report.equipmentAndEngine.hourMeter 
                            : (report.equipmentAndEngine.hours?.toString() ?? ''),
                        unit: 'Hours',
                      ),
                      _buildFormCell('Battery Status / Volt:', report.equipmentAndEngine.batteryStatusVolt, unit: 'V'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // 3. SERVICE CHECKLIST & STATUS
              _buildSectionHeader('3. SERVICE CHECKLIST & STATUS'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(3),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  // Subheader row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E0E7FF')),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: pw.Text('Inspection Parameter', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: pw.Text('Status [ OK / Action ]', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: pw.Text('Inspection Parameter', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: pw.Text('Status [ OK / Action ]', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                      ),
                    ],
                  ),
                  // Data rows
                  ...List.generate(
                    (report.serviceChecklist.length / 2).ceil(),
                    (rowIndex) {
                      final index1 = rowIndex * 2;
                      final index2 = rowIndex * 2 + 1;
                      final item1 = report.serviceChecklist[index1];
                      final item2 = index2 < report.serviceChecklist.length ? report.serviceChecklist[index2] : null;

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: pw.Text(item1.parameter, style: const pw.TextStyle(fontSize: 8.5)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: statusWidget(item1.status),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: pw.Text(item2?.parameter ?? '', style: const pw.TextStyle(fontSize: 8.5)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: item2 != null
    ? statusWidget(item2.status)
    : pw.SizedBox(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // 4. PARTS REPLACED & CONSUMABLES USED
              _buildSectionHeader('4. PARTS REPLACED & CONSUMABLES USED'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(3),
                  3: pw.FlexColumnWidth(2),
                },
                children: partsTableRows,
              ),
              pw.SizedBox(height: 14),

              // 5. TECHNICIAN REMARKS & ACTION PLAN
              _buildSectionHeader('5. TECHNICIAN REMARKS & ACTION PLAN'),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                padding: const pw.EdgeInsets.all(6),
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: 'Observations / Corrective Actions Taken: ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5),
                          ),
                          pw.TextSpan(
                            text: report.remarksAndActionPlan.observations,
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    children: [
                      _buildFormCell(
                        'Next Service Due (Date):',
                        report.remarksAndActionPlan.nextServiceDueDate != null
                            ? DateFormat('dd-MM-yyyy').format(report.remarksAndActionPlan.nextServiceDueDate!)
                            : '',
                      ),
                      _buildFormCell(
                        'Next Service Due (Hours):',
                        report.remarksAndActionPlan.nextServiceDueHours?.toString() ?? '',
                        unit: 'Hours',
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // 6. FIELD WORK AUTHORIZATION & SIGN-OFF
              _buildSectionHeader('6. FIELD WORK AUTHORIZATION & SIGN-OFF'),
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                    right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: pw.Text(
                  'By signing below, the customer representative acknowledges that the field service operations listed above were completed satisfactorily and equipment has been handed over in operational condition.',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  // Table Subheader
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E0E7FF')),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: pw.Text('TECHNICIAN SIGNATURE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: pw.Text('CUSTOMER SIGNATURE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                      ),
                    ],
                  ),
                  // Contents
                  pw.TableRow(
                    children: [
                      // Technician
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: 'Name: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                                  pw.TextSpan(text: report.authorization.technicianName, style: const pw.TextStyle(fontSize: 8.5)),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text('Signature: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                                pw.SizedBox(width: 4),
                                if (signatureImage != null)
                                  pw.Container(
                                    height: 35,
                                    width: 100,
                                    child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                                  )
                                else
                                  pw.Text('', style: const pw.TextStyle(fontSize: 8.5)),
                              ],
                            ),
                            pw.SizedBox(height: 5),
                            pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: 'Date: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                                  pw.TextSpan(
                                    text: report.authorization.technicianDate != null
                                        ? DateFormat('dd-MM-yyyy').format(report.authorization.technicianDate!)
                                        : '_______________________',
                                    style: const pw.TextStyle(fontSize: 8.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Customer
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: 'Name: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                                  pw.TextSpan(text: report.authorization.customerRepresentativeName, style: const pw.TextStyle(fontSize: 8.5)),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text('Signature: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                                pw.SizedBox(width: 4),
                                if (customerPhoto != null)
                                  pw.Container(
                                    height: 35,
                                    width: 70,
                                    child: pw.Image(customerPhoto, fit: pw.BoxFit.cover),
                                  )
                                else
                                  pw.Text('', style: const pw.TextStyle(fontSize: 8.5)),
                              ],
                            ),
                            pw.SizedBox(height: 5),
                            pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: 'Date: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'), fontSize: 8.5)),
                                  pw.TextSpan(
                                    text: report.authorization.customerDate != null
                                        ? DateFormat('dd-MM-yyyy').format(report.authorization.customerDate!)
                                        : '_______________________',
                                    style: const pw.TextStyle(fontSize: 8.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }


  Future<void> printOrSavePdf(ReportModel report) async {
    final bytes = await generatePdf(report);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'eFSR-${report.serviceAndCustomer.jobRef}',
    );
  }

  Future<void> sharePdf(ReportModel report) async {
    final bytes = await generatePdf(report);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/eFSR_${report.serviceAndCustomer.jobRef}.pdf');
    await file.writeAsBytes(bytes);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Diesel Technical Solutions Service Report - ${report.serviceAndCustomer.jobRef}',
    );
  }
}
