// lib/utils/string_extensions.dart

extension StringFormattingExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}"; // Also make rest lowercase for consistency
  }
}
