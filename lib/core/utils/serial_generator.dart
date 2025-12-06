import 'package:uuid/uuid.dart';

class SerialCodeGenerator {
  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = const Uuid().v4().substring(0, 4).toUpperCase();
    return 'RPR$timestamp$uniqueId';
  }

  static String formatSerialCode(String code) {
    // Format: RPR-XXXX-XXXX-XXXX
    if (code.length >= 12) {
      return '${code.substring(0, 3)}-${code.substring(3, 7)}-${code.substring(7, 11)}-${code.substring(11)}';
    }
    return code;
  }
}
