import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String cloudName = 'drs8bfglw';
  static const String apiKey = '738374529618539';
  static const String apiSecret = '2utDV-H4_j0AvmKn7qwNTltBTzM';

  /// Generate signature for Cloudinary API
  /// According to Cloudinary docs, exclude: file, cloud_name, resource_type, api_key
  static String _generateSignature(Map<String, String> params) {
    // Create a copy for signing, excluding fields that should not be in signature
    final signingParams = Map<String, String>.from(params);
    signingParams.remove('signature');
    signingParams.remove('api_key'); // api_key should NOT be in signature
    signingParams.remove('file');
    signingParams.remove('cloud_name');
    signingParams.remove('resource_type');
    
    // Sort parameters alphabetically
    final sortedKeys = signingParams.keys.toList()..sort();
    final signatureString = sortedKeys
        .map((key) => '$key=${signingParams[key]}')
        .join('&');
    final stringToSign = '$signatureString$apiSecret';
    
    // Generate SHA-1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Upload a single image file to Cloudinary
  /// Returns the secure URL of the uploaded image
  static Future<String> uploadImage(File imageFile, {String? folder}) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final fullFileName = imageFile.path.split('/').last;
      final fileName = fullFileName.split('.').first;
      
      // Create unique public_id with timestamp
      final uniqueId = '${fileName}_${DateTime.now().millisecondsSinceEpoch}';
      final publicId = folder != null 
          ? '$folder/$uniqueId'
          : 'traveltalkbd/$uniqueId';

      final params = <String, String>{
        'timestamp': timestamp,
        'public_id': publicId,
        'api_key': apiKey,
      };

      final signature = _generateSignature(params);
      params['signature'] = signature;

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields.addAll(params)
        ..files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['secure_url'] ?? jsonResponse['url'] ?? '';
      } else {
        final errorBody = response.body;
        throw Exception('Upload failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
  }

  /// Upload multiple image files to Cloudinary
  /// Returns a list of secure URLs of the uploaded images
  static Future<List<String>> uploadMultipleImages(
    List<File> imageFiles, {
    String? folder,
  }) async {
    try {
      final List<String> urls = [];
      
      for (final imageFile in imageFiles) {
        final url = await uploadImage(imageFile, folder: folder);
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw Exception('Failed to upload images to Cloudinary: $e');
    }
  }

  /// Upload image from bytes (useful for web platform)
  static Future<String> uploadImageFromBytes(
    Uint8List imageBytes,
    String fileName, {
    String? folder,
  }) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final fileBaseName = fileName.split('.').first;
      
      // Create unique public_id with timestamp
      final uniqueId = '${fileBaseName}_${DateTime.now().millisecondsSinceEpoch}';
      final publicId = folder != null 
          ? '$folder/$uniqueId'
          : 'traveltalkbd/$uniqueId';

      final params = <String, String>{
        'timestamp': timestamp,
        'public_id': publicId,
        'api_key': apiKey,
      };

      final signature = _generateSignature(params);
      params['signature'] = signature;

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      // Ensure filename has extension (default to jpg if missing)
      final fullFileName = fileName.contains('.') ? fileName : '$fileName.jpg';

      final request = http.MultipartRequest('POST', uri)
        ..fields.addAll(params)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: fullFileName,
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['secure_url'] ?? jsonResponse['url'] ?? '';
      } else {
        final errorBody = response.body;
        throw Exception('Upload failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
  }
}
