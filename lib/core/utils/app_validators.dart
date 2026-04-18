import 'package:flutter/material.dart';

class AppValidators {
  // --- Required Field Validator ---
  static FormFieldValidator<String> requiredField(String fieldName) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }

  // --- Email Validator ---
  static FormFieldValidator<String> email() {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Email is required';
      }
      // Fixed the redundant character escape '\.' inside the character class
      final emailRegExp = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegExp.hasMatch(value)) {
        return 'Enter a valid email address';
      }
      return null;
    };
  }

  // --- Password Validator ---
  static FormFieldValidator<String> password() {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Password is required';
      }
      if (value.length < 8) {
        return 'Password must be at least 8 characters';
      }
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'Must contain at least one uppercase letter';
      }
      if (!value.contains(RegExp(r'[0-9]'))) {
        return 'Must contain at least one number';
      }
      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        return 'Must contain at least one special character';
      }
      return null;
    };
  }

  // --- Confirm Password Validator ---
  static FormFieldValidator<String> confirmPassword(String originalPassword) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != originalPassword) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  // --- Phone Validator (Indian Mobile Number) ---
  static FormFieldValidator<String> phone() {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Phone number is required';
      }
      // Indian mobile numbers start with 6-9 and are 10 digits long
      final phoneRegExp = RegExp(r'^[6-9]\d{9}$');
      if (!phoneRegExp.hasMatch(value)) {
        return 'Enter a valid 10-digit Indian phone number';
      }
      return null;
    };
  }

  // --- Pincode Validator (Indian Pincode) ---
  static FormFieldValidator<String> pincode() {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Pincode is required';
      }
      // Indian pincodes are 6 digits and do not start with 0
      final pincodeRegExp = RegExp(r'^[1-9][0-9]{5}$');
      if (!pincodeRegExp.hasMatch(value)) {
        return 'Enter a valid 6-digit pincode';
      }
      return null;
    };
  }

  // --- Name Validator ---
  static FormFieldValidator<String> name() {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Name is required';
      }
      if (value.length < 2) {
        return 'Name must be at least 2 characters';
      }
      // Allows letters and spaces only
      final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
      if (!nameRegExp.hasMatch(value)) {
        return 'Name cannot contain special characters or numbers';
      }
      return null;
    };
  }

  // --- Old vs New Password Validator ---
  static FormFieldValidator<String> oldNewPasswordDifferent(String oldPassword) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'New password is required';
      }
      if (value == oldPassword) {
        return 'New password must be different from the current password';
      }
      return null;
    };
  }
}