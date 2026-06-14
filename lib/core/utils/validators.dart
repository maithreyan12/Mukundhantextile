class Validators {
  Validators._();

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final error = Validators.password(value);
    if (error != null) return error;
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final regex = RegExp(r'^[0-9]{10}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    final regex = RegExp(r'^[0-9]{6}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final n = double.tryParse(value.trim());
    if (n == null || n < 0) {
      return 'Enter a valid price';
    }
    return null;
  }

  static String? stock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock is required';
    }
    final n = int.tryParse(value.trim());
    if (n == null || n < 0) {
      return 'Enter a valid stock quantity';
    }
    return null;
  }
}
