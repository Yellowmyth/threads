import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/thread_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../widgets/thread_card.dart';
import 'profile_page.dart';
import 'login_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _suggestedUsers = [];
  bool _isUsersLoading = true;
  String _selectedCategory = "All";

  final List<String> _categories = [
    "All",
    "Trending",
    "Photography",
    "Technology",
    "Lifestyle",
    "Gaming",
    "Food",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThreadProvider>().fetchThreads(refresh: true);
      _fetchUsers();
    });
  }

  Future<void> _fetchUsers({String search = ''}) async {
    if (!mounted) return;
    setState(() => _isUsersLoading = true);
    try {
      final response = await context.read<AuthProvider>().apiService.get(
        '/users/search.php',
        params: search.isNotEmpty ? {'search': search} : null,
      );
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _suggestedUsers = data.map((e) => UserModel.fromJson(e)).toList();
          _isUsersLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
      if (mounted) setState(() => _isUsersLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: (value) => _fetchUsers(search: value),
            decoration: InputDecoration(
              hintText: "Search threads, people, or topics...",
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _fetchUsers();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchUsers();
          await context.read<ThreadProvider>().fetchThreads(refresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  "Explore Premium v2.0",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  "People you might know",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 220,
                child: _isUsersLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _suggestedUsers.isEmpty
                    ? const Center(child: Text("No users found in database"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestedUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(_suggestedUsers[index]);
                        },
                      ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  "Discover Trending Content",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Consumer<ThreadProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.threads.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (provider.threads.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text("No trending content found."),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.threads.length > 10
                        ? 10
                        : provider.threads.length,
                    itemBuilder: (context, index) {
                      return ThreadCard(thread: provider.threads[index]);
                    },
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      width: 160,
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(userId: user.id.toString()),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage:
                    (user.profileImage != null && user.profileImage!.isNotEmpty)
                    ? CachedNetworkImageProvider(
                        '${AppConstants.uploadsUrl}/profiles/${user.profileImage}',
                      )
                    : null,
                child: (user.profileImage == null || user.profileImage!.isEmpty)
                    ? Text(
                        user.username[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.fullName ?? user.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                "@${user.username}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: () => _handleFollow(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isFollowing
                        ? Colors.grey[100]
                        : AppColors.primary,
                    foregroundColor: user.isFollowing
                        ? Colors.black87
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    user.isFollowing ? "Following" : "Follow",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFollow(UserModel user) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }
    final bool currentlyFollowing = user.isFollowing;
    setState(() {
      int idx = _suggestedUsers.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        _suggestedUsers[idx] = UserModel(
          id: user.id,
          username: user.username,
          email: user.email,
          fullName: user.fullName,
          bio: user.bio,
          profileImage: user.profileImage,
          followersCount: user.followersCount + (currentlyFollowing ? -1 : 1),
          followingCount: user.followingCount,
          isFollowing: !currentlyFollowing,
        );
      }
    });
    try {
      await auth.apiService.post(
        '/users/follow.php',
        {},
        params: {'id': user.id.toString()},
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          int idx = _suggestedUsers.indexWhere((u) => u.id == user.id);
          if (idx != -1) _suggestedUsers[idx] = user;
        });
      }
    }
  }
}
