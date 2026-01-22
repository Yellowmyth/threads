class ThreadModel {
  final int id;
  final int userId;
  final String username;
  final String? fullName;
  final String? profileImage;
  final String content;
  final String? image;
  int likesCount;
  int commentsCount;
  bool isLiked;
  final DateTime createdAt;

  ThreadModel({
    required this.id,
    required this.userId,
    required this.username,
    this.fullName,
    this.profileImage,
    required this.content,
    this.image,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  factory ThreadModel.fromJson(Map<String, dynamic> json) {
    return ThreadModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      profileImage: json['profile_image']?.toString(),
      content: json['content']?.toString() ?? '',
      image: json['image']?.toString(),
      likesCount: int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      commentsCount:
          int.tryParse(json['comments_count']?.toString() ?? '0') ?? 0,
      isLiked:
          json['is_liked'] == true ||
          json['is_liked'] == 1 ||
          json['is_liked'] == '1',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
