import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../domain/models/models.dart';

class ArabicCsvExporter {
  /// Export orders to CSV with Arabic support (UTF-8 with BOM)
  static Future<void> exportOrdersToCsv(
    List<RepairOrder> orders,
    bool isArabic,
  ) async {
    try {
      // Prepare CSV data
      List<List<dynamic>> rows = [];

      // Headers
      if (isArabic) {
        rows.add([
          'رقم التسلسل',
          'التاريخ',
          'العميل',
          'نوع اللابتوب',
          'المشكلة',
          'الحالة',
          'التكلفة الكلية',
          'المدفوع',
          'المتبقي',
        ]);
      } else {
        rows.add([
          'Serial Code',
          'Date',
          'Customer',
          'Laptop Type',
          'Problem',
          'Status',
          'Total Cost',
          'Paid',
          'Remaining',
        ]);
      }

      // Data rows
      for (var order in orders) {
        rows.add([
          order.serialCode,
          DateFormat('yyyy-MM-dd').format(order.createdAt),
          '', // Customer name - will be filled by caller if needed
          order.laptopType,
          order.problemDescription,
          isArabic
              ? _getStatusArabic(order.status)
              : _getStatusEnglish(order.status),
          order.totalCost.toStringAsFixed(2),
          order.paidAmount.toStringAsFixed(2),
          order.remainingAmount.toStringAsFixed(2),
        ]);
      }

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Add UTF-8 BOM for Arabic support in Excel
      final utf8Bom = '\uFEFF';
      final csvWithBom = utf8Bom + csv;

      // Save file
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: isArabic ? 'حفظ ملف CSV' : 'Save CSV File',
        fileName:
            'orders_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath != null) {
        // Write file with UTF-8 encoding
        final file = File(outputPath);
        await file.writeAsString(csvWithBom, encoding: utf8);
        return;
      }
    } catch (e) {
      throw Exception('Error exporting CSV: $e');
    }
  }

  /// Export customers with balances to CSV
  static Future<void> exportCustomerBalances(
    Map<String, Map<String, dynamic>> customerData,
    bool isArabic,
  ) async {
    try {
      List<List<dynamic>> rows = [];

      // Headers
      if (isArabic) {
        rows.add([
          'اسم العميل',
          'رقم الهاتف',
          'الرصيد المستحق',
          'عدد الطلبات',
        ]);
      } else {
        rows.add([
          'Customer Name',
          'Phone',
          'Outstanding Balance',
          'Total Orders',
        ]);
      }

      // Data rows
      customerData.forEach((customerId, data) {
        rows.add([
          data['name'],
          data['phone'],
          data['balance'].toStringAsFixed(2),
          data['orderCount'],
        ]);
      });

      // Convert to CSV with BOM
      String csv = const ListToCsvConverter().convert(rows);
      final utf8Bom = '\uFEFF';
      final csvWithBom = utf8Bom + csv;

      // Save file
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: isArabic ? 'حفظ تقرير الأرصدة' : 'Save Balance Report',
        fileName:
            'customer_balances_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(csvWithBom, encoding: utf8);
      }
    } catch (e) {
      throw Exception('Error exporting customer balances: $e');
    }
  }

  /// Export accessories inventory to CSV
  static Future<void> exportAccessories(
    List<Accessory> accessories,
    bool isArabic,
  ) async {
    try {
      List<List<dynamic>> rows = [];

      // Headers
      if (isArabic) {
        rows.add([
          'الاسم',
          'الفئة',
          'السعر',
          'الكمية المتوفرة',
          'القيمة الإجمالية',
        ]);
      } else {
        rows.add([
          'Name',
          'Category',
          'Price',
          'Stock',
          'Total Value',
        ]);
      }

      // Data rows
      for (var accessory in accessories) {
        rows.add([
          isArabic ? accessory.nameAr : accessory.nameEn,
          isArabic
              ? (accessory.categoryAr ?? 'غير محدد')
              : (accessory.categoryEn ?? 'Uncategorized'),
          accessory.price.toStringAsFixed(2),
          accessory.stockQuantity,
          (accessory.price * accessory.stockQuantity).toStringAsFixed(2),
        ]);
      }

      // Convert to CSV with BOM
      String csv = const ListToCsvConverter().convert(rows);
      final utf8Bom = '\uFEFF';
      final csvWithBom = utf8Bom + csv;

      // Save file
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: isArabic ? 'حفظ قائمة المخزون' : 'Save Inventory List',
        fileName:
            'accessories_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(csvWithBom, encoding: utf8);
      }
    } catch (e) {
      throw Exception('Error exporting accessories: $e');
    }
  }

  static String _getStatusArabic(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'قيد الانتظار';
      case OrderStatus.inProgress:
        return 'قيد الإصلاح';
      case OrderStatus.completed:
        return 'مكتمل';
      case OrderStatus.delivered:
        return 'تم التسليم';
    }
  }

  static String _getStatusEnglish(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }
}
