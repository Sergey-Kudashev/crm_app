import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

const String cloudName = 'dnaese467'; // ⚠️ Публічне, окей
const String uploadPreset = 'pwa_crm_upload';

Future<String?> uploadImageToCloudinary({
  required Uint8List bytes,
  required String fileName,
}) async {
  final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = uploadPreset
    ..fields['public_id'] = fileName
    ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: '$fileName.jpg'));

  try {
    final streamedResponse = await request.send().timeout(const Duration(seconds: 15));

    if (streamedResponse.statusCode == 200) {
      final res = await streamedResponse.stream.bytesToString();
      final json = jsonDecode(res);
      return json['secure_url'];
    } else {
      final error = await streamedResponse.stream.bytesToString();
      print('Cloudinary error ${streamedResponse.statusCode}: $error');
      return null;
    }
  } catch (e) {
    print('Cloudinary exception: $e');
    return null;
  }
}
