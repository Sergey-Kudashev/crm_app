import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Завантажує зображення у Cloudinary за допомогою unsigned preset.
/// [bytes] — це байти зображення
/// [fileName] — бажане ім’я (може бути унікальне, напр. з DateTime)
Future<String?> uploadImageToCloudinary({
  required Uint8List bytes,
  required String fileName,
}) async {
  const cloudName = 'dnaese467'; // ⚠️ Не страшно, це публічне
  const uploadPreset = 'pwa_crm_upload';

  final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = uploadPreset
    ..fields['public_id'] = fileName
    ..files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: '$fileName.jpg',
      ),
    );

  final response = await request.send();

  if (response.statusCode == 200) {
    final res = await response.stream.bytesToString();
    final json = jsonDecode(res);
    return json['secure_url']; // URL завантаженого зображення
  } else {
    print('Помилка Cloudinary: ${response.statusCode}');
    return null;
  }
}
