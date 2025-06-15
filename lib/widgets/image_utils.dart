import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

const String cloudName = 'dnaese467'; // ⚠️ Публічне, окей
const String uploadPreset = 'pwa_crm_upload';

Future<String?> uploadImageToCloudinary({
  required Uint8List bytes,
  required String fileName,
  required String folderPath, // <-- додано
}) async {
  const cloudName = 'dnaese467';
  const uploadPreset = 'pwa_crm_upload';

  final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = uploadPreset
    ..fields['public_id'] = fileName
    ..fields['folder'] = folderPath // <-- використовуємо
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
    return json['secure_url'];
  } else {
    print('Помилка Cloudinary: ${response.statusCode}');
    return null;
  }
}

