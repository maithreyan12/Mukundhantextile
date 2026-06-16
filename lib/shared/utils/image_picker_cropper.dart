import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Simple, reliable image picker utility.
/// No crop — just picks images cleanly for upload.
class ImagePickerHelper {
  static final _picker = ImagePicker();

  /// Pick a single image from gallery
  static Future<XFile?> pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      return file;
    } catch (e) {
      debugPrint('⚠️ Image pick failed: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  static Future<List<XFile>> pickMultipleImages() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      return files;
    } catch (e) {
      debugPrint('⚠️ Image pick failed: $e');
      return [];
    }
  }
}
