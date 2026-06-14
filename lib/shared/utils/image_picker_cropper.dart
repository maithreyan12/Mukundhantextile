import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

/// Reusable image picker with crop functionality.
/// Works on both Web and Mobile (Android/iOS).
class ImagePickerCropper {
  static final _picker = ImagePicker();

  /// Pick a single image and crop it.
  /// [aspectRatio] — e.g. CropAspectRatio(ratioX: 16, ratioY: 9) for banners
  /// [title] — displayed in the cropper toolbar
  static Future<XFile?> pickAndCrop(
    BuildContext context, {
    CropAspectRatioPreset? preset,
    CropAspectRatio? aspectRatio,
    String title = 'Crop Image',
  }) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return null;

    return _cropFile(context, file, preset: preset, aspectRatio: aspectRatio, title: title);
  }

  /// Pick multiple images and crop each one.
  static Future<List<XFile>> pickMultipleAndCrop(
    BuildContext context, {
    CropAspectRatioPreset? preset,
    CropAspectRatio? aspectRatio,
    String title = 'Crop Image',
  }) async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return [];

    final List<XFile> croppedFiles = [];
    for (final file in files) {
      final cropped = await _cropFile(
        context, file,
        preset: preset,
        aspectRatio: aspectRatio,
        title: title,
      );
      if (cropped != null) {
        croppedFiles.add(cropped);
      }
    }
    return croppedFiles;
  }

  /// Internal: Crop a single XFile
  static Future<XFile?> _cropFile(
    BuildContext context,
    XFile file, {
    CropAspectRatioPreset? preset,
    CropAspectRatio? aspectRatio,
    String title = 'Crop Image',
  }) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        // Android UI settings
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: isDark ? const Color(0xFF1A1A2E) : primaryColor,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: primaryColor,
          backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
          initAspectRatio: preset ?? CropAspectRatioPreset.original,
          lockAspectRatio: aspectRatio != null,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio3x2,
          ],
        ),
        // iOS UI settings
        IOSUiSettings(
          title: title,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio3x2,
          ],
          aspectRatioLockEnabled: aspectRatio != null,
        ),
        // Web UI settings
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(width: 520, height: 520),
          zoomable: true,
          zoomOnWheel: true,
        ),
      ],
    );

    if (croppedFile != null) {
      return XFile(croppedFile.path);
    }
    return null;
  }
}
