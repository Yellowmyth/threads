import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/thread_provider.dart';
import '../widgets/thread_card.dart';
import '../utils/constants.dart';
import '../services/preference_service.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../widgets/custom_textfield.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _prefService = PreferenceService();
  final _appTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile(widget.userId);
    });
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      context.read<ProfileProvider>().fetchProfile(widget.userId);
    }
  }

  Future<void> _loadSettings() async {
    try {
      String title = await _prefService.getAppTitle();
      if (mounted) {
        setState(() {
          _appTitleController.text = title;
        });
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id.toString();
    final isOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.profileUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.profileUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProfileProvider>().fetchProfile(
                        widget.userId,
                      );
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final user = provider.profileUser;
          if (user == null) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(child: Text("User not found"));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 0),
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage:
                          (user.profileImage != null &&
                              user.profileImage!.isNotEmpty)
                          ? CachedNetworkImageProvider(
                              '${AppConstants.uploadsUrl}/profiles/${user.profileImage}?v=${provider.cacheBuster}',
                            )
                          : null,
                      child:
                          (user.profileImage == null ||
                              user.profileImage!.isEmpty)
                          ? Text(
                              (user.username.isNotEmpty)
                                  ? user.username[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(
                                fontSize: 32,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      (user.fullName != null && user.fullName!.isNotEmpty)
                          ? user.fullName!
                          : user.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "@${user.username}",
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        user.bio!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (user.email.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.email,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatColumn(
                          label: "Followers",
                          count: user.followersCount,
                        ),
                        const SizedBox(width: 40),
                        _StatColumn(
                          label: "Following",
                          count: user.followingCount,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!isOwnProfile)
                      ElevatedButton(
                        onPressed: () => provider.toggleFollow(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isFollowing
                              ? Colors.grey.shade200
                              : AppColors.primary,
                          foregroundColor: user.isFollowing
                              ? Colors.black
                              : Colors.white,
                        ),
                        child: Text(user.isFollowing ? "UNFOLLOW" : "FOLLOW"),
                      )
                    else
                      OutlinedButton(
                        onPressed: () {
                          _showEditProfile(context, user);
                        },
                        child: const Text("Edit Profile"),
                      ),
                    const Divider(height: 40),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Threads",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              if (provider.userThreads.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("No threads yet")),
                )
              else
                ...provider.userThreads
                    .map((t) => ThreadCard(thread: t))
                    .toList(),
              const SizedBox(height: 50),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _appTitleController.dispose();
    super.dispose();
  }

  void _showEditProfile(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditProfileSheet(user: user),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserModel user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  final _picker = ImagePicker();
  XFile? _image;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.user.fullName ?? "",
    );
    _bioController = TextEditingController(text: widget.user.bio ?? "");
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Edit Profile",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: _image != null
                  ? (kIsWeb
                        ? NetworkImage(_image!.path)
                        : FileImage(File(_image!.path)) as ImageProvider)
                  : (widget.user.profileImage != null &&
                            widget.user.profileImage!.isNotEmpty
                        ? CachedNetworkImageProvider(
                            '${AppConstants.uploadsUrl}/profiles/${widget.user.profileImage}?v=${context.read<ProfileProvider>().cacheBuster}',
                          )
                        : null),
              child:
                  (_image == null &&
                      (widget.user.profileImage == null ||
                          widget.user.profileImage!.isEmpty))
                  ? Text(
                      widget.user.username.isNotEmpty
                          ? widget.user.username[0].toUpperCase()
                          : "?",
                      style: const TextStyle(
                        fontSize: 24,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Change Photo",
            style: TextStyle(color: Colors.blue, fontSize: 12),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _fullNameController,
            label: "Full Name",
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _bioController,
            label: "Bio",
            icon: Icons.info_outline,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return auth.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () async {
                          bool success = await auth.updateProfile(
                            fullName: _fullNameController.text,
                            bio: _bioController.text,
                            profileImage: _image,
                          );

                          if (success && context.mounted) {
                            // Refresh the profile data in ProfileProvider
                            context.read<ProfileProvider>().fetchProfile(
                              widget.user.id.toString(),
                            );

                            // Refresh logic for other providers
                            if (context.mounted) {
                              context.read<ThreadProvider>().fetchThreads(
                                refresh: true,
                              );
                            }

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Profile updated!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to update. Try again."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text("SAVE"),
                      );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int count;
  const _StatColumn({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}
