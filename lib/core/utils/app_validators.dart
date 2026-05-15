import 'package:flutter/material.dart';

class AppValidators {
  // PROD PERFORMANCE FIX: Compile Regular Expressions exactly once in memory
  // rather than re-compiling them on every single keystroke.
  static final RegExp _emailRegExp = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp _uppercaseRegExp = RegExp(r'[A-Z]');
  static final RegExp _numberRegExp = RegExp(r'[0-9]');
  static final RegExp _specialCharRegExp = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  static final RegExp _phoneRegExp = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _pincodeRegExp = RegExp(r'^[1-9][0-9]{5}$');
  static final RegExp _nameRegExp = RegExp(r'^[a-zA-Z\s]+$');

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
      if (!_emailRegExp.hasMatch(value)) {
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
      if (!_uppercaseRegExp.hasMatch(value)) {
        return 'Must contain at least one uppercase letter';
      }
      if (!_numberRegExp.hasMatch(value)) {
        return 'Must contain at least one number';
      }
      if (!_specialCharRegExp.hasMatch(value)) {
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
      if (!_phoneRegExp.hasMatch(value)) {
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
      if (!_pincodeRegExp.hasMatch(value)) {
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
      if (!_nameRegExp.hasMatch(value)) {
        return 'Name cannot contain special characters or numbers';
      }
      return null;
    };
  }

  // --- Old vs New Password Validator ---
  static FormFieldValidator<String> oldNewPasswordDifferent(
    String oldPassword,
  ) {
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
