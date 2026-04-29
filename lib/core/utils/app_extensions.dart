import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_config.dart';
import '../theme/app_colors.dart';

// --- String Extensions ---
extension StringExtension on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${toUpperCase()}${substring(1)}';
  }

  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  String get toOrderId {
    if (isEmpty) return '#ORD-UNKNOWN';
    if (length > 5) {
      return '#ORD-${substring(length - 5).toUpperCase()}';
    }
    return '#ORD-${toUpperCase()}';
  }
}

// --- Double Extensions ---
extension DoubleExtension on double {
  String toCurrency() {
    int decimals = this == truncateToDouble() ? 0 : 2;
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: decimals,
    );
    return format.format(this);
  }

  String toPercent() {
    return '${toStringAsFixed(0)}%';
  }
}

// --- DateTime Extensions ---
extension DateTimeExtension on DateTime {
  String toDisplayDate() {
    return DateFormat('dd MMM yyyy').format(this);
  }

  String toDisplayDateTime() {
    return DateFormat('dd MMM yyyy, hh:mm a').format(this);
  }

  String timeAgo() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

// --- BuildContext Extensions ---
extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError ? AppColors.kError : AppColors.kAccentIndigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void showLoadingDialog() {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.kAccentIndigo),
        ),
      ),
    );
  }

  void hideDialog() {
    if (Navigator.canPop(this)) {
      Navigator.pop(this);
    }
  }

  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }
}

extension ImageUrlExtension on String {
  String get toEmulatorUrl {
    // Only swap if we are in development mode on the Android Emulator
    if (AppConfig.currentEnvironment == AppEnvironment.dev &&
        contains('localhost')) {
      return replaceAll('localhost', '10.0.2.2');
    }
    return this;
  }
}
