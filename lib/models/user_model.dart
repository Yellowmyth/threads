class UserModel {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String? bio;
  final String? profileImage;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.bio,
    this.profileImage,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      bio: json['bio']?.toString(),
      profileImage: json['profile_image']?.toString(),
      followersCount:
          int.tryParse(json['followers_count']?.toString() ?? '0') ?? 0,
      followingCount:
          int.tryParse(json['following_count']?.toString() ?? '0') ?? 0,
      isFollowing:
          json['is_following'] == true ||
          json['is_following'] == 1 ||
          json['is_following'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'bio': bio,
      'profile_image': profileImage,
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_following': isFollowing,
    };
  }
}
