import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/models.dart';
import 'package:flutter/services.dart' show rootBundle;

class ReceiptPrinter {
  static Future<pw.Font> _loadArabicFont() async {
    // Load Cairo font for Arabic support
    try {
      final fontData = await rootBundle.load('fonts/Cairo-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      print('Error loading Cairo font: $e');
      // Fallback: Try to load any available font
      final fontData = await rootBundle.load('fonts/Cairo-Regular.ttf');
      return pw.Font.ttf(fontData);
    }
  }

  static Future<void> printReceipt(
    RepairOrder order,
    Customer? customer,
    Dealer? dealer,
  ) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();

    // Determine customer name
    String customerName = 'غير محدد';
    String customerPhone = 'لا يوجد';

    if (customer != null) {
      customerName = customer.name;
      customerPhone = customer.phone;
    } else if (dealer != null) {
      customerName = dealer.name;
      if (order.deviceOwnerName != null) {
        customerName = '$customerName (${order.deviceOwnerName})';
      }
      customerPhone = dealer.phone;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                'الريان لصيانة اللابتوب',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),

              // Serial Code & QR
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: order.serialCode,
                      width: 100,
                      height: 100,
                    ),
                    pw.Text(
                      order.serialCode,
                      style: pw.TextStyle(
                        fontSize: 12,
                        font: arabicFont,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Order Details - Full width with RTL
              pw.Container(
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildRow(arabicFont, 'العميل:', customerName),
                    _buildRow(arabicFont, 'الهاتف:', customerPhone),
                    _buildRow(arabicFont, 'الجهاز:', order.laptopType),
                    _buildRow(arabicFont, 'المشكلة:', order.problemDescription),
                  ],
                ),
              ),
              pw.Divider(),

              // Financial - Full width
              pw.Container(
                width: double.infinity,
                child: pw.Column(
                  children: [
                    _buildRow(arabicFont, 'التكلفة:',
                        '${order.totalCost.toStringAsFixed(2)} ج.م'),
                    _buildRow(arabicFont, 'المدفوع:',
                        '${order.paidAmount.toStringAsFixed(2)} ج.م'),
                    _buildRow(
                      arabicFont,
                      'المتبقي:',
                      '${order.remainingAmount.toStringAsFixed(2)} ج.م',
                      bold: true,
                    ),
                  ],
                ),
              ),

              // Accessories
              if (order.accessories.isNotEmpty) ...[
                pw.Divider(),
                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'الإكسسوارات:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: arabicFont,
                          fontSize: 12,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      ...order.accessories.map(
                        (acc) => _buildRow(
                          arabicFont,
                          '  ${acc.accessoryNameAr}',
                          '${acc.totalPrice.toStringAsFixed(2)} ج.م',
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              pw.Divider(),
              pw.SizedBox(height: 10),

              // Footer
              pw.Text(
                'شكراً لتعاملكم معنا',
                style: pw.TextStyle(
                  fontSize: 12,
                  font: arabicFont,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.Text(
                'تاريخ: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: arabicFont,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _buildRow(pw.Font font, String label, String value,
      {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        // textDirection: pw.TextDirection.rtl,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                font: font,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                font: font,
              ),
              textDirection: pw.TextDirection.rtl,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
