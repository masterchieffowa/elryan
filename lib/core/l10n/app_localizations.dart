import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  // General
  String get appName => isArabic ? 'الريان' : 'ELRAYAN';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get add => isArabic ? 'إضافة' : 'Add';
  String get search => isArabic ? 'بحث' : 'Search';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get yes => isArabic ? 'نعم' : 'Yes';
  String get no => isArabic ? 'لا' : 'No';
  String get close => isArabic ? 'إغلاق' : 'Close';

  // Authentication
  String get login => isArabic ? 'تسجيل الدخول' : 'Login';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get changePassword =>
      isArabic ? 'تغيير كلمة المرور' : 'Change Password';
  String get currentPassword =>
      isArabic ? 'كلمة المرور الحالية' : 'Current Password';
  String get newPassword => isArabic ? 'كلمة المرور الجديدة' : 'New Password';
  String get confirmPassword =>
      isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get incorrectPassword =>
      isArabic ? 'كلمة مرور خاطئة' : 'Incorrect Password';
  String get passwordChanged =>
      isArabic ? 'تم تغيير كلمة المرور' : 'Password Changed';

  // Dashboard
  String get dashboard => isArabic ? 'لوحة التحكم' : 'Dashboard';
  String get totalOrders => isArabic ? 'إجمالي الطلبات' : 'Total Orders';
  String get pendingOrders => isArabic ? 'طلبات معلقة' : 'Pending Orders';
  String get completedOrders => isArabic ? 'طلبات مكتملة' : 'Completed Orders';
  String get totalRevenue => isArabic ? 'إجمالي الإيرادات' : 'Total Revenue';
  String get outstandingBalance =>
      isArabic ? 'المبالغ المستحقة' : 'Outstanding Balance';

  // Orders
  String get orders => isArabic ? 'الطلبات' : 'Orders';
  String get newOrder => isArabic ? 'طلب جديد' : 'New Order';
  String get orderDetails => isArabic ? 'تفاصيل الطلب' : 'Order Details';
  String get laptopType => isArabic ? 'نوع اللابتوب' : 'Laptop Type';
  String get problemDescription =>
      isArabic ? 'وصف المشكلة' : 'Problem Description';
  String get repairCost => isArabic ? 'تكلفة الإصلاح' : 'Repair Cost';
  String get paidAmount => isArabic ? 'المبلغ المدفوع' : 'Paid Amount';
  String get remainingAmount =>
      isArabic ? 'المبلغ المتبقي' : 'Remaining Amount';
  String get orderStatus => isArabic ? 'حالة الطلب' : 'Order Status';
  String get createdDate => isArabic ? 'تاريخ الإنشاء' : 'Created Date';
  String get completedDate => isArabic ? 'تاريخ الإكمال' : 'Completed Date';
  String get deliveredDate => isArabic ? 'تاريخ التسليم' : 'Delivered Date';

  // Status
  String get pending => isArabic ? 'قيد الانتظار' : 'Pending';
  String get inProgress => isArabic ? 'قيد الإصلاح' : 'In Progress';
  String get completed => isArabic ? 'مكتمل' : 'Completed';
  String get delivered => isArabic ? 'تم التسليم' : 'Delivered';

  // Customers
  String get customers => isArabic ? 'العملاء' : 'Customers';
  String get newCustomer => isArabic ? 'عميل جديد' : 'New Customer';
  String get customerName => isArabic ? 'اسم العميل' : 'Customer Name';
  String get phoneNumber => isArabic ? 'رقم الهاتف' : 'Phone Number';
  String get address => isArabic ? 'العنوان' : 'Address';
  String get customerDetails => isArabic ? 'تفاصيل العميل' : 'Customer Details';
  String get customerHistory => isArabic ? 'سجل العميل' : 'Customer History';

  // Accessories
  String get accessories => isArabic ? 'الإكسسوارات' : 'Accessories';
  String get newAccessory => isArabic ? 'إكسسوار جديد' : 'New Accessory';
  String get accessoryNameAr =>
      isArabic ? 'اسم الإكسسوار (عربي)' : 'Accessory Name (Arabic)';
  String get accessoryNameEn =>
      isArabic ? 'اسم الإكسسوار (إنجليزي)' : 'Accessory Name (English)';
  String get price => isArabic ? 'السعر' : 'Price';
  String get stockQuantity => isArabic ? 'الكمية المتوفرة' : 'Stock Quantity';
  String get addToOrder => isArabic ? 'إضافة للطلب' : 'Add to Order';
  String get quantity => isArabic ? 'الكمية' : 'Quantity';

  // Payments
  String get payments => isArabic ? 'المدفوعات' : 'Payments';
  String get addPayment => isArabic ? 'إضافة دفعة' : 'Add Payment';
  String get paymentAmount => isArabic ? 'مبلغ الدفع' : 'Payment Amount';
  String get paymentDate => isArabic ? 'تاريخ الدفع' : 'Payment Date';
  String get paymentHistory => isArabic ? 'سجل المدفوعات' : 'Payment History';
  String get notes => isArabic ? 'ملاحظات' : 'Notes';

  // Reports
  String get reports => isArabic ? 'التقارير' : 'Reports';
  String get revenueReport => isArabic ? 'تقرير الإيرادات' : 'Revenue Report';
  String get pendingOrdersReport =>
      isArabic ? 'تقرير الطلبات المعلقة' : 'Pending Orders Report';
  String get customerBalances =>
      isArabic ? 'أرصدة العملاء' : 'Customer Balances';
  String get exportToCSV => isArabic ? 'تصدير إلى CSV' : 'Export to CSV';
  String get selectDateRange =>
      isArabic ? 'اختر نطاق التاريخ' : 'Select Date Range';
  String get from => isArabic ? 'من' : 'From';
  String get to => isArabic ? 'إلى' : 'To';

  // Settings
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get language => isArabic ? 'اللغة' : 'Language';
  String get theme => isArabic ? 'المظهر' : 'Theme';
  String get lightMode => isArabic ? 'وضع فاتح' : 'Light Mode';
  String get darkMode => isArabic ? 'وضع داكن' : 'Dark Mode';
  String get backup => isArabic ? 'نسخ احتياطي' : 'Backup';
  String get restore => isArabic ? 'استعادة' : 'Restore';
  String get backupDatabase =>
      isArabic ? 'نسخ قاعدة البيانات' : 'Backup Database';
  String get restoreDatabase =>
      isArabic ? 'استعادة قاعدة البيانات' : 'Restore Database';

  // Messages
  String get noData => isArabic ? 'لا توجد بيانات' : 'No Data';
  String get loading => isArabic ? 'جاري التحميل...' : 'Loading...';
  String get success => isArabic ? 'نجح' : 'Success';
  String get error => isArabic ? 'خطأ' : 'Error';
  String get deleteConfirm =>
      isArabic ? 'هل أنت متأكد من الحذف؟' : 'Are you sure you want to delete?';
  String get saveSuccess => isArabic ? 'تم الحفظ بنجاح' : 'Saved Successfully';
  String get deleteSuccess =>
      isArabic ? 'تم الحذف بنجاح' : 'Deleted Successfully';

  // Validation
  String get fieldRequired =>
      isArabic ? 'هذا الحقل مطلوب' : 'This field is required';
  String get invalidNumber => isArabic ? 'رقم غير صحيح' : 'Invalid Number';
  String get invalidPhone =>
      isArabic ? 'رقم هاتف غير صحيح' : 'Invalid Phone Number';
  String get passwordMismatch =>
      isArabic ? 'كلمات المرور غير متطابقة' : 'Passwords do not match';

  // Currency
  String currency(double amount) {
    return isArabic
        ? '${amount.toStringAsFixed(2)} ج.م'
        : 'EGP ${amount.toStringAsFixed(2)}';
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
