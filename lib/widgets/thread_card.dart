import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/thread_model.dart';
import '../providers/thread_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../pages/profile_page.dart';
import '../pages/login_page.dart';
import 'comment_sheet.dart';

class ThreadCard extends StatelessWidget {
  final ThreadModel thread;

  const ThreadCard({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isCurrentUser = auth.user != null && auth.user!.id == thread.userId;

    // Use latest data from AuthProvider if it's the current user's thread
    final displayProfileImage = isCurrentUser
        ? auth.user!.profileImage
        : thread.profileImage;
    final displayFullName = isCurrentUser
        ? (auth.user!.fullName ?? auth.user!.username)
        : (thread.fullName ?? thread.username);
    final displayUsername = isCurrentUser
        ? auth.user!.username
        : thread.username;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfilePage(userId: thread.userId.toString()),
                  ),
                ),
                child: CircleAvatar(
                  key: ValueKey(
                    'profile_${thread.userId}_${isCurrentUser ? auth.cacheBuster : "static"}',
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage:
                      (displayProfileImage != null &&
                          displayProfileImage.isNotEmpty)
                      ? CachedNetworkImageProvider(
                          '${AppConstants.uploadsUrl}/profiles/$displayProfileImage?v=${auth.cacheBuster}',
                        )
                      : null,
                  child:
                      (displayProfileImage == null ||
                          displayProfileImage.isEmpty)
                      ? Text(
                          displayUsername.isNotEmpty
                              ? displayUsername[0].toUpperCase()
                              : "?",
                          style: const TextStyle(color: AppColors.primary),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayFullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "@$displayUsername",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _timeAgo(thread.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            thread.content,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          if (thread.image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: '${AppConstants.uploadsUrl}/threads/${thread.image}',
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey.shade100,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const SizedBox(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _ActionButton(
                icon: thread.isLiked ? Icons.favorite : Icons.favorite_border,
                color: thread.isLiked ? Colors.red : AppColors.textSecondary,
                label: thread.likesCount.toString(),
                onTap: () {
                  if (auth.user == null) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                    return;
                  }
                  context.read<ThreadProvider>().toggleLike(thread.id);
                },
              ),
              const SizedBox(width: 24),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                color: AppColors.textSecondary,
                label: thread.commentsCount.toString(),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CommentSheet(thread: thread),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 7) return "${(duration.inDays / 7).floor()}w";
    if (duration.inDays > 0) return "${duration.inDays}d";
    if (duration.inHours > 0) return "${duration.inHours}h";
    if (duration.inMinutes > 0) return "${duration.inMinutes}m";
    return "now";
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
