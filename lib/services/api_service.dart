import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static const String keyToken = "auth_token";
  static const String keyUserId = "user_numeric_id";

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyToken);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserId);
  }

  Future<void> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserId, id);
  }

  Future<void> deleteUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUserId);
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await getToken();
    return {
      'Content-Type': 'application/json',
      // Assuming the backend uses X-User-ID to carry the token (legacy behavior behavior check)
      // Or if it expects Authorization. Given previous code used 'user_id' pref for this,
      // and 'saveToken' saved to it, we must ensure we send the TOKEN here.
      if (token != null) 'X-User-ID': token,
    };
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    var uri = Uri.parse(
      '${AppConstants.baseUrl}$endpoint',
    ).replace(queryParameters: params);
    var headers = await _getHeaders();
    return await http.get(uri, headers: headers);
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? params,
  }) async {
    var uri = Uri.parse(
      '${AppConstants.baseUrl}$endpoint',
    ).replace(queryParameters: params);
    var headers = await _getHeaders();
    return await http.post(uri, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? params,
  }) async {
    var uri = Uri.parse(
      '${AppConstants.baseUrl}$endpoint',
    ).replace(queryParameters: params);
    var headers = await _getHeaders();
    return await http.put(uri, headers: headers, body: jsonEncode(body));
  }

  Future<String?> uploadImage(XFile imageFile, String type) async {
    var uri = Uri.parse('${AppConstants.baseUrl}/upload/image.php');
    var request = http.MultipartRequest('POST', uri);

    request.fields['type'] = type;

    String? token = await getToken();
    if (token != null) {
      request.headers['X-User-ID'] = token;
    }

    var bytes = await imageFile.readAsBytes();

    String extension = imageFile.name.split('.').last.toLowerCase();
    MediaType contentType;
    if (extension == 'png') {
      contentType = MediaType('image', 'png');
    } else if (extension == 'gif') {
      contentType = MediaType('image', 'gif');
    } else {
      contentType = MediaType('image', 'jpeg');
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
        contentType: contentType,
      ),
    );

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);
      return data['filename'];
    } else {
      debugPrint("Upload failed with status: ${response.statusCode}");
      var errorData = await response.stream.bytesToString();
      debugPrint("Error body: $errorData");
    }
    return null;
  }
}
