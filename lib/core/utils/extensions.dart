// BuildContext responsive/theme extensions are in app_responsive.dart (ResponsiveContext).
// Re-export so any file that imports extensions.dart also gets context helpers.
export 'app_responsive.dart' show ResponsiveContext, AppResponsive, AppDeviceType;

/// String extensions for common operations
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }
  
  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');
  
  /// Check if string is empty or contains only whitespace
  bool get isBlank => trim().isEmpty;
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Format as "Jan 1, 2024"
  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[month - 1]} $day, $year';
  }
  
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }
}

/// BuildContext extensions are provided by app_responsive.dart (ResponsiveContext).
/// See core/utils/app_responsive.dart for all context helpers: rs(), rFont(), rVSpace() etc.

