import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/models.dart';

class ReceiptPrinter {
  static Future<void> printReceipt(
    RepairOrder order,
    Customer? customer,
    Dealer? dealer,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'الريان لصيانة اللابتوب',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
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
                    pw.Text(order.serialCode,
                        style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Order Details
              _buildRow(
                  'العميل:', customer?.name ?? dealer?.name ?? 'غير محدد'),
              _buildRow('الهاتف:', customer?.phone ?? dealer?.phone ?? ''),
              _buildRow('الجهاز:', order.laptopType),
              _buildRow('المشكلة:', order.problemDescription),
              pw.Divider(),

              // Financial
              _buildRow('التكلفة:', '${order.totalCost} ج.م'),
              _buildRow('المدفوع:', '${order.paidAmount} ج.م'),
              _buildRow('المتبقي:', '${order.remainingAmount} ج.م', bold: true),

              // Accessories
              if (order.accessories.isNotEmpty) ...[
                pw.Divider(),
                pw.Text('الإكسسوارات:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...order.accessories.map(
                  (acc) => _buildRow(
                      '  ${acc.accessoryNameAr}', '${acc.totalPrice} ج.م'),
                ),
              ],

              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                  child: pw.Text('شكراً لتعاملكم معنا',
                      style: const pw.TextStyle(fontSize: 12))),
              pw.Center(
                  child: pw.Text('تاريخ: ${DateTime.now()}',
                      style: const pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _buildRow(String label, String value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
