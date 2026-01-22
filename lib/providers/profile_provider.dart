import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/thread_model.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel? _profileUser;
  List<ThreadModel> _userThreads = [];
  bool _isLoading = false;

  String? _errorMessage;
  String _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();

  UserModel? get profileUser => _profileUser;
  List<ThreadModel> get userThreads => _userThreads;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get cacheBuster => _cacheBuster;

  Future<void> fetchProfile(String userId) async {
    if (userId.isEmpty || userId == "null") {
      _errorMessage = "Invalid User ID";
      _isLoading = false;
      notifyListeners();
      return;
    }

    _profileUser = null;
    _userThreads = [];
    _errorMessage = null;
    _isLoading = true;
    _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
    notifyListeners();

    debugPrint("Fetching profile for userId: $userId");

    try {
      // Fetch user details
      var userRes = await _apiService.get(
        '/users/profile.php',
        params: {'id': userId},
      );

      if (userRes.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(userRes.body);
        // Handle both wrapped (in 'user' or 'data' key) and unwrapped response
        if (data.containsKey('user')) {
          _profileUser = UserModel.fromJson(data['user']);
        } else if (data.containsKey('data')) {
          _profileUser = UserModel.fromJson(data['data']);
        } else {
          _profileUser = UserModel.fromJson(data);
        }
      } else {
        _errorMessage =
            "Failed to load profile (Status: ${userRes.statusCode})";
      }

      // Only fetch threads if user profile was successfully loaded
      if (_profileUser != null) {
        var threadsRes = await _apiService.get(
          '/threads/feed.php',
          params: {'user_id': userId},
        );
        if (threadsRes.statusCode == 200) {
          dynamic threadsData = jsonDecode(threadsRes.body);
          if (threadsData is List) {
            _userThreads = threadsData
                .map((e) => ThreadModel.fromJson(e))
                .toList();
          } else if (threadsData is Map && threadsData.containsKey('data')) {
            _userThreads = (threadsData['data'] as List)
                .map((e) => ThreadModel.fromJson(e))
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      _errorMessage = "Connection Error: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFollow() async {
    if (_profileUser == null) return;

    try {
      var response = await _apiService.post(
        '/users/follow.php',
        {},
        params: {'id': _profileUser!.id.toString()},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _profileUser = UserModel(
          id: _profileUser!.id,
          username: _profileUser!.username,
          email: _profileUser!.email,
          fullName: _profileUser!.fullName,
          bio: _profileUser!.bio,
          profileImage: _profileUser!.profileImage,
          followersCount:
              int.tryParse(data['followers_count']?.toString() ?? '0') ?? 0,
          followingCount: _profileUser!.followingCount,
          isFollowing: !(_profileUser!.isFollowing),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error toggling follow: $e");
    }
  }
}
