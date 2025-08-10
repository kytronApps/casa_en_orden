import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarService {
  AvatarService(this.supabase);
  final SupabaseClient supabase;

  static const bucket = 'avatars-casa-en-orden';

  Future<String?> signedUrlForProfile(String profileId) async {
    final row = await supabase
        .from('cleaning_profiles')
        .select('avatar_path')
        .eq('id', profileId)
        .maybeSingle();
    final path = row?['avatar_path'] as String?;
    if (path == null) return null;
    return await supabase.storage.from(bucket).createSignedUrl(path, 3600);
  }

  Future<String?> pickAndUploadForProfile({
    required String userId,
    required String profileId,
  }) async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return null;

    final bytes = await x.readAsBytes();
    final ext = x.path.split('.').last.toLowerCase();
    final mime = lookupMimeType(x.path) ?? 'image/jpeg';
    final path = '$userId/$profileId/avatar.$ext';

    await supabase.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: mime, cacheControl: '3600'),
    );

    await supabase.from('cleaning_profiles')
      .update({'avatar_path': path})
      .eq('id', profileId);

    return await supabase.storage.from(bucket).createSignedUrl(path, 3600);
  }
}
