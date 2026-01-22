class CommentModel {
  final int id;
  final int threadId;
  final int userId;
  final String username;
  final String? profileImage;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.threadId,
    required this.userId,
    required this.username,
    this.profileImage,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: int.parse(json['id'].toString()),
      threadId: int.parse(json['thread_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      username: json['username'] ?? '',
      profileImage: json['profile_image'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
