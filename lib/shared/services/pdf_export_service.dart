// ignore_for_file: avoid_web_libraries_in_flutter, avoid_print, unused_import, deprecated_member_use
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:html' as html;

class PdfExportService {
  /// Exportar reportes de ventas a PDF
  static Future<String> exportReportsToPdf({
    required String title,
    required String period,
    required DateTime? startDate,
    required DateTime? endDate,
    required double totalSales,
    required int totalOrders,
    required double avgTicket,
    required int cashOrders,
    required Map<String, double> categorySales,
    required List<Map<String, dynamic>> topProducts,
  }) async {
    // Crear documento
    final pdf = pw.Document();
    
    // Formato de fecha
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BellezApp - Reporte de Ventas',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Período: $period',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                if (startDate != null && endDate != null)
                  pw.Text(
                    'Rango: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                pw.Text(
                  'Fecha de generación: ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
              ],
            ),
          ),

          // Resumen de Ventas
          pw.Text(
            'RESUMEN DE VENTAS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey400,
              width: 1,
            ),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text(
                      'Métrica',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text(
                      'Valor',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text('Ventas Totales'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text(currencyFormat.format(totalSales)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text('Total de Órdenes'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text('$totalOrders'),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text('Ticket Promedio'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text(currencyFormat.format(avgTicket)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text('Pagos en Efectivo'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Text('$cashOrders'),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Ventas por Categoría
          pw.Text(
            'VENTAS POR CATEGORÍA',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 15),
          if (categorySales.isEmpty)
            pw.Text('No hay datos de categorías en este período')
          else
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 1,
              ),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(
                        'Categoría',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(
                        'Ventas',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(
                        'Porcentaje',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...categorySales.entries.map((entry) {
                  final percentage = totalSales > 0 
                      ? (entry.value / totalSales * 100) 
                      : 0.0;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text(entry.key),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text(currencyFormat.format(entry.value)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text('${percentage.toStringAsFixed(1)}%'),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          pw.SizedBox(height: 30),

          // Top Productos
          pw.Text(
            'TOP 5 PRODUCTOS MÁS VENDIDOS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 15),
          if (topProducts.isEmpty)
            pw.Text('No hay datos en este período')
          else
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 1,
              ),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(
                        'Posición',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(
                        'Producto',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text(
                        'Ventas',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...topProducts.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final product = entry.value;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text('$index'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text(product['name'] ?? 'Sin nombre'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text(
                          currencyFormat.format(product['totalSales'] ?? 0.0),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          pw.SizedBox(height: 30),

          // Footer
          pw.Divider(),
          pw.Text(
            'Este reporte fue generado automáticamente por BellezApp',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );

    // Guardar PDF
    try {
      final timestamp = DateFormat('dd_MM_yyyy_HH_mm_ss').format(DateTime.now());
      final filename = 'reporte_ventas_$timestamp.pdf';
      final pdfBytes = await pdf.save();
      
      if (kIsWeb) {
        // Para web, descargar el archivo
        _downloadFileWeb(filename, pdfBytes);
        return 'reporte_ventas_$timestamp.pdf'; // Retorna el nombre del archivo
      } else {
        // Para plataformas nativas (Windows, macOS, Linux, Android, iOS)
        final output = await getApplicationDocumentsDirectory();
        final file = io.File('${output.path}/$filename');
        await file.writeAsBytes(pdfBytes);
        return file.path;
      }
    } catch (e) {
      throw Exception('Error al guardar PDF: $e');
    }
  }

  /// Descargar archivo en web
  static void _downloadFileWeb(String filename, List<int> bytes) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }
}
