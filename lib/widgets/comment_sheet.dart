import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/thread_model.dart';
import '../models/comment_model.dart';
import '../providers/thread_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentSheet extends StatefulWidget {
  final ThreadModel thread;

  const CommentSheet({super.key, required this.thread});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final _commentController = TextEditingController();
  List<CommentModel>? _comments;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final comments = await context.read<ThreadProvider>().fetchComments(
      widget.thread.id,
    );
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final success = await context.read<ThreadProvider>().addComment(
      widget.thread.id,
      _commentController.text,
    );

    if (success && mounted) {
      _commentController.clear();
      _loadComments(); // Refresh comments list
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            "Comments",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_comments == null || _comments!.isEmpty)
                ? const Center(child: Text("No comments yet"))
                : ListView.builder(
                    itemCount: _comments!.length,
                    itemBuilder: (context, index) {
                      final comment = _comments![index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage:
                              (comment.profileImage != null &&
                                  comment.profileImage!.isNotEmpty)
                              ? CachedNetworkImageProvider(
                                  '${AppConstants.uploadsUrl}/profiles/${comment.profileImage}',
                                )
                              : null,
                          child:
                              (comment.profileImage == null ||
                                  comment.profileImage!.isEmpty)
                              ? Text(
                                  comment.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          comment.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          comment.content,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        trailing: Text(
                          _timeAgo(comment.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Input Section
          if (auth.isAuthenticated)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _submitComment,
                    icon: const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "Login to participate in the conversation",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) return "${duration.inDays}d";
    if (duration.inHours > 0) return "${duration.inHours}h";
    if (duration.inMinutes > 0) return "${duration.inMinutes}m";
    return "now";
  }
}
