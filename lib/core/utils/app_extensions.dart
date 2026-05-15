import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_config.dart';
import '../theme/app_colors.dart';

// --- String Extensions ---
extension StringExtension on String {
  String get capitalize {
    if (isEmpty) return this;
    // PROD BUG FIX: Only capitalize the very first letter, not the whole string
    return '${this.toUpperCase()}${substring(1)}';
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
    return DateFormat('dd MMM yyyy').format(toLocal());
  }

  String toDisplayDateTime() {
    return DateFormat('dd MMM yyyy, hh:mm a').format(toLocal());
  }

  String timeAgo() {
    final now = DateTime.now();
    // PROD FIX: Always convert backend timestamps to local device time before comparing
    final localTime = toLocal();
    final difference = now.difference(localTime);

    // Guard against negative differences if device time is slightly behind server time
    if (difference.isNegative) {
      return 'Just now';
    }

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
    // PROD UX FIX: Clear existing SnackBars to prevent overlapping queues
    ScaffoldMessenger.of(this).clearSnackBars();

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
    // PROD FIX: Delegate to the secure method we already built in app_config.dart
    // This prevents dart:io web crashes and maintains a single source of truth.
    return AppConfig.sanitizeImageUrl(this);
  }
}
