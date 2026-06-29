import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
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

    final headersStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900, fontSize: 10);
    final dataLabelStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
    final dataValStyle = const pw.TextStyle(fontSize: 9);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // PDF Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 120,
                    height: 50,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Text('DTS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ELECTRONIC FIELD SERVICE REPORT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Job Ref: ${report.serviceAndCustomer.jobRef}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${report.serviceAndCustomer.dateTime.toLocal().toString().substring(0, 16)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1.5, color: PdfColors.blue900),
            pw.SizedBox(height: 10),

            // Service & Customer Details Table
            pw.Text('1. SERVICE & CUSTOMER DETAILS', style: headersStyle),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  children: [
                    _buildTableCell('Customer Name', report.serviceAndCustomer.customerName, dataLabelStyle, dataValStyle),
                    _buildTableCell('Site ID / Location', report.serviceAndCustomer.siteLocation, dataLabelStyle, dataValStyle),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildTableCell('Contact Person', report.serviceAndCustomer.contactPerson, dataLabelStyle, dataValStyle),
                    _buildTableCell('Contact Number', report.serviceAndCustomer.contactNumber, dataLabelStyle, dataValStyle),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Equipment & Engine Details
            pw.Text('2. EQUIPMENT & GENERATOR DETAILS', style: headersStyle),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  children: [
                    _buildTableCell('Generator Make/Model', report.equipmentAndEngine.generatorMakeModel, dataLabelStyle, dataValStyle),
                    _buildTableCell('Capacity (kVA/kW)', report.equipmentAndEngine.capacity, dataLabelStyle, dataValStyle),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildTableCell('Engine Serial No', report.equipmentAndEngine.engineSerialNo, dataLabelStyle, dataValStyle),
                    _buildTableCell('Alternator Serial No', report.equipmentAndEngine.alternatorSerialNo, dataLabelStyle, dataValStyle),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildTableCell('Hour Meter', report.equipmentAndEngine.hourMeter, dataLabelStyle, dataValStyle),
                    _buildTableCell('Hours', report.equipmentAndEngine.hours?.toString() ?? 'N/A', dataLabelStyle, dataValStyle),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildTableCell('Battery Status Volt', report.equipmentAndEngine.batteryStatusVolt, dataLabelStyle, dataValStyle),
                    pw.SizedBox(), // Blank block to balance table
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Checklist Section
            pw.Text('3. SERVICE CHECKLIST & STATUS', style: headersStyle),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(1),
              },
              children: List.generate(
                (report.serviceChecklist.length / 2).ceil(),
                (rowIndex) {
                  final index1 = rowIndex * 2;
                  final index2 = rowIndex * 2 + 1;

                  final item1 = report.serviceChecklist[index1];
                  final item2 = index2 < report.serviceChecklist.length 
                      ? report.serviceChecklist[index2] 
                      : null;

                  return pw.TableRow(
                    children: [
                      _buildChecklistCell(item1.parameter, item1.status.toUpperCase(), dataLabelStyle, dataValStyle),
                      if (item2 != null)
                        _buildChecklistCell(item2.parameter, item2.status.toUpperCase(), dataLabelStyle, dataValStyle)
                      else
                        pw.SizedBox(),
                    ],
                  );
                },
              ),
            ),
            pw.SizedBox(height: 16),

            // Parts Replaced
            pw.Text('4. PARTS REPLACED & CONSUMABLES USED', style: headersStyle),
            pw.SizedBox(height: 6),
            if (report.partsUsed.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Text('No parts replaced or consumables used.', style: dataValStyle),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Part Description / Item', style: dataLabelStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Quantity', style: dataLabelStyle)),
                    ],
                  ),
                  ...report.partsUsed.map(
                    (p) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p.partDescription, style: dataValStyle)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p.qty, style: dataValStyle)),
                      ],
                    ),
                  ),
                ],
              ),
            pw.SizedBox(height: 16),

            // Remarks Section
            pw.Text('5. REMARKS & ACTION PLAN', style: headersStyle),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  children: [
                    _buildTableCell('Observations / Remarks', report.remarksAndActionPlan.observations, dataLabelStyle, dataValStyle),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildTableCell(
                      'Next Service Due Date',
                      report.remarksAndActionPlan.nextServiceDueDate != null
                          ? report.remarksAndActionPlan.nextServiceDueDate!.toLocal().toString().substring(0, 10)
                          : 'N/A',
                      dataLabelStyle,
                      dataValStyle,
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildTableCell(
                      'Next Service Due Hours',
                      report.remarksAndActionPlan.nextServiceDueHours?.toString() ?? 'N/A',
                      dataLabelStyle,
                      dataValStyle,
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Authorization & Signatures Section
            pw.Text('6. FIELD WORK AUTHORIZATION & SIGN-OFF', style: headersStyle),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Technician Signature', style: dataLabelStyle),
                          pw.Text('Name: ${report.authorization.technicianName}', style: dataValStyle),
                          pw.SizedBox(height: 8),
                          if (signatureImage != null)
                            pw.Container(
                              height: 60,
                              width: 150,
                              child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                            )
                          else
                            pw.Text('[Signature Saved]', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8)),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Customer representative Photo', style: dataLabelStyle),
                          pw.Text('Name: ${report.authorization.customerRepresentativeName}', style: dataValStyle),
                          pw.SizedBox(height: 8),
                          if (customerPhoto != null)
                            pw.Container(
                              height: 60,
                              width: 120,
                              child: pw.Image(customerPhoto, fit: pw.BoxFit.cover),
                            )
                          else
                            pw.Text('[Photo Captured]', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTableCell(String label, String value, pw.TextStyle labelStyle, pw.TextStyle valStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: labelStyle),
          pw.SizedBox(height: 2),
          pw.Text(value.isNotEmpty ? value : 'N/A', style: valStyle),
        ],
      ),
    );
  }

  pw.Widget _buildChecklistCell(String parameter, String status, pw.TextStyle labelStyle, pw.TextStyle valStyle) {
    final statusColor = status == 'OK' 
        ? PdfColors.green700 
        : (status == 'REQ' ? PdfColors.blue700 : PdfColors.grey600);
        
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: pw.Text(parameter, style: valStyle)),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: statusColor, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(status, style: pw.TextStyle(color: statusColor, fontWeight: pw.FontWeight.bold, fontSize: 7)),
          ),
        ],
      ),
    );
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
