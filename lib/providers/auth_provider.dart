import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = false;
  String _errorMessage = '';
  String _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String get errorMessage => _errorMessage;
  String get cacheBuster => _cacheBuster;

  Future<void> init() async {
    String? token = await _apiService.getToken();
    String? userId = await _apiService.getUserId();

    if (token != null && userId != null) {
      await fetchUserDetails(userId);
    }
  }

  Future<void> fetchUserDetails(String userId) async {
    try {
      var response = await _apiService.get(
        '/users/profile.php',
        params: {'id': userId},
      );
      if (response.statusCode == 200) {
        _user = UserModel.fromJson(jsonDecode(response.body));
        _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      var response = await _apiService.post('/auth/login.php', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await _apiService.saveToken(data['token']);
        _user = UserModel.fromJson(data['user']);
        await _apiService.saveUserId(_user!.id.toString());
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? bio,
    XFile? profileImage,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      String? imageName;
      if (profileImage != null) {
        imageName = await _apiService.uploadImage(profileImage, 'profiles');
      }

      var body = {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName ?? '',
        'bio': bio ?? '',
        'profile_image': imageName ?? '',
      };

      var response = await _apiService.post('/auth/register.php', body);

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        try {
          var data = jsonDecode(response.body);
          _errorMessage =
              data['error'] ?? data['message'] ?? "Registration failed";
        } catch (e) {
          _errorMessage = "Server error: ${response.statusCode}";
        }
        debugPrint("Registration failed: ${response.statusCode}");
        debugPrint("Error body: ${response.body}");
      }
    } catch (e) {
      _errorMessage = "An error occurred: $e";
      debugPrint("Register error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateProfile({
    required String fullName,
    required String bio,
    XFile? profileImage,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? imageName;
      if (profileImage != null) {
        imageName = await _apiService.uploadImage(profileImage, 'profiles');
      }

      var body = {'full_name': fullName, 'bio': bio};

      if (imageName != null) {
        body['profile_image'] = imageName;
      }

      var response = await _apiService.post('/users/update_profile.php', body);

      if (response.statusCode == 200) {
        if (_user != null) {
          await fetchUserDetails(_user!.id.toString());
        }
        _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Update profile error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _apiService.deleteToken();
    await _apiService.deleteUserId();
    _user = null;
    notifyListeners();
  }
}
