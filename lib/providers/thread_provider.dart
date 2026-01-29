import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../models/thread_model.dart';
import '../models/comment_model.dart';
import '../services/api_service.dart';

class ThreadProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ThreadModel> _threads = [];
  bool _isLoading = false;
  int _offset = 0;
  bool _hasMore = true;

  String? _errorMessage;

  List<ThreadModel> get threads => _threads;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> fetchThreads({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _threads = [];
      _hasMore = true;
      // Don't return if refresh is true, we want to force a reload
    } else if (!_hasMore || _isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var response = await _apiService.get(
        '/threads/feed.php',
        params: {'limit': '20', 'offset': _offset.toString()},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<ThreadModel> newThreads = data
            .map((e) => ThreadModel.fromJson(e))
            .toList();

        if (newThreads.length < 20) {
          _hasMore = false;
        }

        _threads.addAll(newThreads);
        _offset += newThreads.length;
      } else {
        _errorMessage =
            "Failed to load threads (Status: ${response.statusCode})";
      }
    } catch (e) {
      debugPrint("Error fetching threads: $e");
      _errorMessage = "Connection error: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createThread(
    String content,
    XFile? imageFile,
    int userId,
  ) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      String? imageName;
      if (imageFile != null) {
        imageName = await _apiService.uploadImage(imageFile, 'threads');
      }

      var response = await _apiService.post('/threads/create.php', {
        'user_id': userId.toString(),
        'content': content,
        'image': imageName ?? "",
      });

      if (response.statusCode == 201) {
        await fetchThreads(refresh: true);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Failed to post (Status: ${response.statusCode})";
      }
    } catch (e) {
      debugPrint("Error creating thread: $e");
      _errorMessage = "Error: $e";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> toggleLike(int threadId) async {
    int index = _threads.indexWhere((t) => t.id == threadId);
    if (index == -1) return;

    // Optimistic update
    final originalIsLiked = _threads[index].isLiked;
    final originalLikesCount = _threads[index].likesCount;

    _threads[index].isLiked = !originalIsLiked;
    _threads[index].likesCount += _threads[index].isLiked ? 1 : -1;
    notifyListeners();

    try {
      var response = await _apiService.post(
        '/threads/like.php',
        {},
        params: {'id': threadId.toString()},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // Sync with actual count from server
        if (data['likes_count'] != null) {
          _threads[index].likesCount =
              int.tryParse(data['likes_count'].toString()) ??
              _threads[index].likesCount;
          notifyListeners();
        }
      } else {
        // Revert on failure
        _threads[index].isLiked = originalIsLiked;
        _threads[index].likesCount = originalLikesCount;
        notifyListeners();
        debugPrint(
          "Like failed with status: ${response.statusCode}. Body: ${response.body}",
        );
      }
    } catch (e) {
      // Revert on error
      _threads[index].isLiked = originalIsLiked;
      _threads[index].likesCount = originalLikesCount;
      notifyListeners();
      debugPrint("Error liking thread: $e");
    }
  }

  Future<List<CommentModel>> fetchComments(int threadId) async {
    try {
      var response = await _apiService.get(
        '/threads/comments.php',
        params: {'id': threadId.toString()},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => CommentModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching comments: $e");
    }
    return [];
  }

  Future<bool> addComment(int threadId, String content) async {
    try {
      var response = await _apiService.post(
        '/threads/comment.php',
        {'content': content},
        params: {'id': threadId.toString()},
      );

      if (response.statusCode == 201) {
        // Update local comment count
        int index = _threads.indexWhere((t) => t.id == threadId);
        if (index != -1) {
          _threads[index].commentsCount++;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint("Error adding comment: $e");
    }
    return false;
  }
}
