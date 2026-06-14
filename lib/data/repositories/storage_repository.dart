import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class StorageRepository {
  final SupabaseClient _client;

  StorageRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ── Upload Image ──────────────────────────────────────
  Future<String> uploadImage({
    required String bucket,
    required XFile file,
    String? folder,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last;
    final fileName = '${const Uuid().v4()}.$ext';
    final path = folder != null ? '$folder/$fileName' : fileName;

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$ext',
          ),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  // ── Upload Multiple Images ────────────────────────────
  Future<List<String>> uploadImages({
    required String bucket,
    required List<XFile> files,
    String? folder,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadImage(bucket: bucket, file: file, folder: folder);
      urls.add(url);
    }
    return urls;
  }

  // ── Delete Image ──────────────────────────────────────
  Future<void> deleteImage({
    required String bucket,
    required String path,
  }) async {
    await _client.storage.from(bucket).remove([path]);
  }

  // ── Extract path from public URL ──────────────────────
  String extractPath(String publicUrl, String bucket) {
    final base = _client.storage.from(bucket).getPublicUrl('');
    return publicUrl.replaceFirst(base, '');
  }
}
