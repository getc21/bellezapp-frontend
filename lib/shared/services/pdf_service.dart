// ignore_for_file: avoid_print, implementation_imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart';

class PdfService {
  // ...existing code...
  static Future<String> generateInventoryRotationPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final products = data['products'] as List? ?? [];
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte de Rotación de Inventario', startDate, endDate),
          pw.SizedBox(height: 20),
          
          // Resumen
          _buildSummarySection(
            'Resumen General',
            [
              ('Rotación Promedio', '${summary['averageRotationRate']?.toStringAsFixed(2) ?? '0'} veces'),
              ('Productos Activos', '${summary['totalProducts'] ?? 0}'),
              ('Productos Rápidos', '${summary['fastMovingProducts'] ?? 0}'),
              ('Productos Lentos', '${summary['slowMovingProducts'] ?? 0}'),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Tabla de productos
          pw.Text('Análisis por Producto', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildProductsTable(products),
        ],
      ),
    );

    return await _savePdf(pdf, 'Rotacion_Inventario_${DateFormat('dd-MM-yyyy').format(DateTime.now())}');
  }

  static Future<String> generateProfitabilityPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final products = data['products'] as List? ?? [];
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte de Rentabilidad', startDate, endDate),
          pw.SizedBox(height: 20),
          
          // Resumen financiero
          _buildSummarySection(
            'Resumen Financiero',
            [
              ('Ventas Totales', '\$${(summary['totalRevenue'] ?? 0).toStringAsFixed(2)}'),
              ('Ganancia', '\$${(summary['totalProfit'] ?? 0).toStringAsFixed(2)}'),
              ('Margen Promedio', '${(summary['averageProfitMargin'] ?? 0).toStringAsFixed(1)}%'),
              ('Productos', '${summary['productCount'] ?? 0}'),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Tabla de rentabilidad
          pw.Text('Rentabilidad por Producto', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildProfitabilityTable(products),
        ],
      ),
    );

    return await _savePdf(pdf, 'Rentabilidad_${DateFormat('dd-MM-yyyy').format(DateTime.now())}');
  }

  static Future<String> generateSalesTrendsPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
    required String period,
  }) async {
    final pdf = pw.Document();
    
    final trends = data['trends'] as List? ?? [];
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte de Tendencias de Ventas', startDate, endDate),
          pw.SizedBox(height: 20),
          
          // Resumen de tendencias
          _buildSummarySection(
            'Resumen de Tendencias',
            [
              ('Ventas Totales', '\$${(summary['totalRevenue'] ?? 0).toStringAsFixed(2)}'),
              ('Total Órdenes', '${summary['totalOrders'] ?? 0}'),
              ('Promedio Diario', '\$${(summary['averageDaily'] ?? 0).toStringAsFixed(2)}'),
              ('Valor Promedio Orden', '\$${(summary['averageOrderValue'] ?? 0).toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 20),
          
          pw.Text('Período: ${_getPeriodLabel(period)}', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 10),
          
          // Tabla de tendencias
          _buildTrendsTable(trends),
        ],
      ),
    );

    return await _savePdf(pdf, 'Tendencias_Ventas_${DateFormat('dd-MM-yyyy').format(DateTime.now())}');
  }

  static Future<String> generateComparisonPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    
    final comparison = data['comparison'] as Map<String, dynamic>? ?? {};
    final current = comparison['currentPeriod'] as Map<String, dynamic>? ?? {};
    final previous = comparison['previousPeriod'] as Map<String, dynamic>? ?? {};
    final productComparisons = data['productComparisons'] as List? ?? [];
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte Comparativo', startDate, endDate),
          pw.SizedBox(height: 20),
          
          // Comparación de métricas principales
          pw.Text('Comparación de Métricas Principales', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildComparisonTable(current, previous, comparison),
          pw.SizedBox(height: 20),
          
          // Tabla de comparación de productos
          if (productComparisons.isNotEmpty) ...[
            pw.Text('Top 10 Productos - Comparación', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildProductComparisonTable(productComparisons),
          ]
        ],
      ),
    );

    return await _savePdf(pdf, 'Comparacion_Periodos_${DateFormat('dd-MM-yyyy').format(DateTime.now())}');
  }

  //

  static pw.Widget _buildHeader(String title, DateTime startDate, DateTime endDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Período: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(String title, List<(String, String)> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: items.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(item.$1, style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 5),
                  pw.Text(item.$2, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProductsTable(List products) {
    return pw.TableHelper.fromTextArray(
      headers: ['Producto', 'Stock', 'Vendidos', 'Tasa', 'Dias', 'Estado'],
      data: products.take(20).map((p) {
        final daysToSell = p['daysToSellStock'] ?? 0;
        final rotationRate = p['rotationRate'] ?? 0;
        final statusText = p['status'] ?? 'normal';
        
        String status;
        switch (statusText) {
          case 'fast':
            status = 'Rapido';
            break;
          case 'slow':
            status = 'Lento';
            break;
          default:
            status = 'Normal';
        }
        
        return [
          (p['productName'] ?? '').toString().substring(0, (p['productName'] ?? '').length > 30 ? 30 : (p['productName'] ?? '').length),
          '${p['currentStock'] ?? 0}',
          '${p['totalSold'] ?? 0}',
          '${rotationRate.toStringAsFixed(2)}x',
          '${daysToSell.toStringAsFixed(1)}',
          status,
        ];
      }).toList(),
      border: pw.TableBorder.all(width: 0.5),
      cellHeight: 20,
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  static pw.Widget _buildProfitabilityTable(List products) {
    return pw.TableHelper.fromTextArray(
      headers: ['Producto', 'Cant', 'Ordenes', 'Ingresos', 'Costo', 'Ganancia', 'Margen%'],
      data: products.take(20).map((p) {
        final margin = p['profitMargin'] ?? 0;
        return [
          (p['productName'] ?? '').toString().substring(0, (p['productName'] ?? '').length > 25 ? 25 : (p['productName'] ?? '').length),
          '${p['totalQuantity'] ?? 0}',
          '${p['orderCount'] ?? 0}',
          '\$${(p['totalRevenue'] ?? 0).toStringAsFixed(2)}',
          '\$${(p['totalCost'] ?? 0).toStringAsFixed(2)}',
          '\$${(p['totalProfit'] ?? 0).toStringAsFixed(2)}',
          '${margin.toStringAsFixed(1)}%',
        ];
      }).toList(),
      border: pw.TableBorder.all(width: 0.5),
      cellHeight: 20,
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  static pw.Widget _buildTrendsTable(List trends) {
    return pw.TableHelper.fromTextArray(
      headers: ['Periodo', 'Ordenes', 'Ingresos', 'Items', 'Promedio'],
      data: trends.map((t) {
        final period = t['period'] ?? '';
        String formattedPeriod;
        try {
          final date = DateTime.parse(period.toString());
          formattedPeriod = DateFormat('dd/MM/yyyy').format(date);
        } catch (e) {
          formattedPeriod = period.toString();
        }
        
        return [
          formattedPeriod,
          '${t['orderCount'] ?? 0}',
          '\$${(t['totalRevenue'] ?? 0).toStringAsFixed(2)}',
          '${t['totalItems'] ?? 0}',
          '\$${(t['averageOrderValue'] ?? 0).toStringAsFixed(2)}',
        ];
      }).toList(),
      border: pw.TableBorder.all(width: 0.5),
      cellHeight: 20,
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  static pw.Widget _buildComparisonTable(
    Map<String, dynamic> current,
    Map<String, dynamic> previous,
    Map<String, dynamic> comparison,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Metrica', 'Periodo Actual', 'Anterior', 'Crecimiento%'],
      data: [
        [
          'Ventas Totales',
          '\$${(current['totalSales'] ?? 0).toStringAsFixed(2)}',
          '\$${(previous['totalSales'] ?? 0).toStringAsFixed(2)}',
          '${(comparison['salesGrowth'] ?? 0).toStringAsFixed(1)}%',
        ],
        [
          'Numero Ordenes',
          '${current['totalOrders'] ?? 0}',
          '${previous['totalOrders'] ?? 0}',
          '${(comparison['ordersGrowth'] ?? 0).toStringAsFixed(1)}%',
        ],
        [
          'Ticket Promedio',
          '\$${(current['averageOrderValue'] ?? 0).toStringAsFixed(2)}',
          '\$${(previous['averageOrderValue'] ?? 0).toStringAsFixed(2)}',
          '${(comparison['avgOrderValueGrowth'] ?? 0).toStringAsFixed(1)}%',
        ],
        [
          'Total Items',
          '${current['totalItems'] ?? 0}',
          '${previous['totalItems'] ?? 0}',
          'N/A',
        ],
      ],
      border: pw.TableBorder.all(width: 0.5),
      cellHeight: 25,
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      cellStyle: const pw.TextStyle(fontSize: 10),
    );
  }

  static pw.Widget _buildProductComparisonTable(List products) {
    return pw.TableHelper.fromTextArray(
      headers: ['Producto', 'Ventas Act', 'Cant Act', 'Ventas Ant', 'Cant Ant', 'Crec%'],
      data: products.take(10).map((p) {
        final growth = p['growth'] ?? 0;
        return [
          (p['productName'] ?? '').toString().substring(0, (p['productName'] ?? '').length > 20 ? 20 : (p['productName'] ?? '').length),
          '\$${(p['currentSales'] ?? 0).toStringAsFixed(2)}',
          '${p['currentQuantity'] ?? 0}',
          '\$${(p['previousSales'] ?? 0).toStringAsFixed(2)}',
          '${p['previousQuantity'] ?? 0}',
          '${growth.toStringAsFixed(1)}%',
        ];
      }).toList(),
      border: pw.TableBorder.all(width: 0.5),
      cellHeight: 20,
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  static String _getPeriodLabel(String period) {
    switch (period) {
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      default:
        return period;
    }
  }

  static Future<String> _savePdf(pw.Document pdf, String filename) async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/$filename.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Abrir el PDF automáticamente
      await OpenFilex.open(file.path);
      
      return file.path;
    } catch (e) {
      rethrow;
    }
  }
}
