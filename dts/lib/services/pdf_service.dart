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
import '../models/agreement_model.dart';
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

  Future<Uint8List> generateAgreementPdf(AgreementModel agreement) async {
    final pdf = pw.Document();

    // 1. Load Logo from Assets
    pw.ImageProvider? logoImage;
    try {
      final logoBytes = (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      // Fallback
    }

    // 2. Load Network/Local Images for Customer Signature & Technician Signature
    pw.ImageProvider? customerSignatureImage;
    pw.ImageProvider? technicianSignatureImage;

    if (agreement.customerSignatureUrl != null && agreement.customerSignatureUrl!.isNotEmpty) {
      final resolvedUrl = _resolveUrl(agreement.customerSignatureUrl!);
      if (resolvedUrl.startsWith('http')) {
        customerSignatureImage = await _loadNetworkImage(resolvedUrl);
      } else {
        final file = File(resolvedUrl);
        if (await file.exists()) {
          try {
            customerSignatureImage = pw.MemoryImage(await file.readAsBytes());
          } catch (e) {
            // Ignore
          }
        }
      }
    }

    if (agreement.technicianSignatureUrl.isNotEmpty) {
      final resolvedUrl = _resolveUrl(agreement.technicianSignatureUrl);
      if (resolvedUrl.startsWith('http')) {
        technicianSignatureImage = await _loadNetworkImage(resolvedUrl);
      } else {
        final file = File(resolvedUrl);
        if (await file.exists()) {
          try {
            technicianSignatureImage = pw.MemoryImage(await file.readAsBytes());
          } catch (e) {
            // Ignore
          }
        }
      }
    }

    pw.Widget buildHeader(pw.ImageProvider? logo, String docType) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Left logo
          pw.Expanded(
            flex: 2,
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: logo != null
                  ? pw.Container(
                      width: 150,
                      height: 50,
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    )
                  : pw.Text('DTS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0B2545'))),
            ),
          ),
          
          // Center details
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'DIESEL TECHNICAL SOLUTIONS',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#000000')),
                ),
                pw.SizedBox(height: 2),
              ],
            ),
          ),

          // Right title
          pw.Expanded(
            flex: 2,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                docType,
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#D97706')), // Gold color
              ),
            ),
          ),
        ],
      );
    }

    pw.Widget buildFooter() {
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            'Thank you for your business...!',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic, color: PdfColor.fromHex('#D97706')),
          ),
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 0.5, color: PdfColors.grey500),
          pw.SizedBox(height: 2),
          pw.Text(
            'D NO: 2-2-212, Laxma Reddy Colony, Uppal, HYD',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 1),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Ph No : 8121312253, Mail : ',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
              ),
              pw.Text(
                'dieseltechnicalsolutions@gmail.com',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#2563EB'),
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // ================= PAGE 1 =================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              buildHeader(logoImage, agreement.documentType),
              pw.SizedBox(height: 10),
              
              // Offer No & Date
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Offer No: - ${agreement.offerNumber ?? 'GPS/AMC/01'}',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(agreement.date)}',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
              ),
              pw.SizedBox(height: 10),

              // Sub-headings
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Annual Maintenance Contract (AMC)',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline, color: PdfColors.black),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Offer for Annual Maintenance Contract (AMC) for Diesel Generator sets.',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic, color: PdfColors.black),
                ),
              ),
              pw.SizedBox(height: 12),

              // Terms 1 to 11
              _buildBulletItem(1, 'Our Service Engineer will make 6 free visits in year to the Engine / DG set at site with intervals of 60days not exceeding 70days.'),
              _buildBulletItem(2, 'During each visit, our Service Engineer will inspect the Engine / DG set and carry out various checks, adjustments. Necessary minor repairs also are carried out by providing required spares parts with you.'),
              _buildBulletItem(3, 'Major repairs like top Over-Hauling, Major Over-Hauling and Third party repair/jobs will carried out only after your specific approval, at extra cost.'),
              _buildBulletItem(4, 'AMC customers are to be treated as our valuable customers, and if any complaint from you, our service team will attend the site on priority basis.'),
              _buildBulletItem(5, 'Depends on terms of contract, one visit will be made every month on a specific date as mutually agreed, failure of which we shall depute our Engineer on any day of the month as convenient to us and to be honored by you. The contract shall be deemed executed on last day of the period completed and further renewal of the contract shall be as mutually agreed.'),
              _buildBulletItem(6, 'Where ever necessary skilled and un-skilled Labor, Tools, Stores, Lifting and Moving facility for completion of the job should be provided by you.'),
              _buildBulletItem(7, "In addition to carrying out normal checking, adjustment and minor repairs, our Service Engineer will acquaint your technical staff / Non Technical staff, who is responsible for the normal operation and maintenance of the engine, with Dos and Don'ts of correct operation and maintenance and the watch points for trouble-shooting."),
              _buildBulletItem(8, "Services offered under this contract will be in accordance with the original Manufacture's standard service instruction practices to maintain the engine in healthy operating condition. However the responsibility of maintaining the engine is with the customer only by following the manufacturer's instructions and recommendation."),
              _buildBulletItem(9, 'All parts including consumable like engine oil are to be procured either from us or from any authorized sources, failing which we will discontinue the contract service.'),
              _buildBulletItem(10, 'Any Statement / Commitment by our Service Staff is binding on us only, if subsequently confirmed by us in writing.'),
              _buildBulletItem(11, 'This offer covers Engine, Alternator & DG Control Panel only and other electrical & Consumables, service parts are not in the purview of this contract, which may please be noted. Separate AMC would be taken if any additional DG sets with you.'),
              
              pw.Spacer(),
              buildFooter(),
            ],
          );
        },
      ),
    );

    // ================= PAGE 2 =================
    final itemsRows = <pw.TableRow>[];
    // Subheader row for items
    itemsRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('S.No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('Rate/Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('Sub Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
          ),
        ],
      ),
    );

    for (int i = 0; i < agreement.descriptionItems.length; i++) {
      final item = agreement.descriptionItems[i];
      itemsRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text((i + 1).toString(), style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(item.quantity.toString(), style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(item.rate.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(item.subTotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
            ),
          ],
        ),
      );
    }

    // Add Grand Total row inside items table
    itemsRows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(''),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('Grand Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(''),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(''),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(agreement.grandTotal.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
          ),
        ],
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              buildHeader(logoImage, agreement.documentType),
              pw.SizedBox(height: 10),

              // Terms 12 and 13
              _buildBulletItem(12, 'All visits will be acknowledged by dually signing the Report on the same day.'),
              _buildBulletItem(13, 'Payment Terms: 100% payment as advance along with copy of the offer with acceptance of Terms and Conditions.', isBold: true),
              pw.SizedBox(height: 12),

              // Validity & assuring
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('This offer is valid for 30 Days from the date of submission.', style: const pw.TextStyle(fontSize: 8.5)),
              ),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('Thanking you and assuring our best services at all times.', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 12),

              // Customer address box
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Name & Address:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Text(agreement.customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                    pw.Text(agreement.completeAddress, style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Contact: ${agreement.contactPerson}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Mob. No : ${agreement.mobileNumber}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.8),
                  1: pw.FlexColumnWidth(4.5),
                  2: pw.FlexColumnWidth(0.8),
                  3: pw.FlexColumnWidth(1.5),
                  4: pw.FlexColumnWidth(1.5),
                },
                children: itemsRows,
              ),
              
              // Amount in words
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.black, width: 0.5),
                    right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: pw.Text(
                  agreement.amountInWords ?? '',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 8),

              // Note box
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Note: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black, fontSize: 8.5),
                    ),
                    pw.TextSpan(
                      text: 'The above Price is only for Service visits, Spares extra at actual.\n',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black, fontSize: 8.5, fontStyle: pw.FontStyle.italic),
                    ),
                    pw.TextSpan(
                      text: 'All expenses for traveling, lodging and boarding for deputation of service engineer will be borne by us.',
                      style: const pw.TextStyle(color: PdfColors.black, fontSize: 8.5),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Signatures Area
              pw.Text('Yours faithfully', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
              pw.Text('For Diesel technical solutions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
              pw.SizedBox(height: 10),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Authorized
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (technicianSignatureImage != null)
                        pw.Container(
                          height: 30,
                          width: 80,
                          child: pw.Image(technicianSignatureImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.SizedBox(height: 30),
                      pw.SizedBox(height: 4),
                      pw.Text('[Authorized Signature]', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                    ],
                  ),

                  // Customer Signatory
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (customerSignatureImage != null)
                        pw.Container(
                          height: 30,
                          width: 80,
                          child: pw.Image(customerSignatureImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.SizedBox(height: 30),
                      pw.SizedBox(height: 4),
                      pw.Text('[Customer Signatory]', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),
              buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildBulletItem(int num, String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 15,
            child: pw.Text('$num)', style: const pw.TextStyle(fontSize: 8.5)),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> printOrSaveAgreementPdf(AgreementModel agreement) async {
    final bytes = await generateAgreementPdf(agreement);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Agreement-${agreement.offerNumber ?? agreement.customerName}',
    );
  }

  Future<void> shareAgreementPdf(AgreementModel agreement) async {
    final bytes = await generateAgreementPdf(agreement);
    final tempDir = await getTemporaryDirectory();
    final sanitizedOfferNumber = (agreement.offerNumber ?? agreement.customerName)
        .replaceAll('/', '_')
        .replaceAll('\\', '_');
    final file = File('${tempDir.path}/Agreement_$sanitizedOfferNumber.pdf');
    await file.writeAsBytes(bytes);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Diesel Technical Solutions AMC Proposal - ${agreement.offerNumber ?? agreement.customerName}',
    );
  }
}
