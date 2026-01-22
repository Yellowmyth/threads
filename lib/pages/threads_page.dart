import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/thread_provider.dart';
import '../widgets/thread_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'profile_page.dart';

class ThreadsPage extends StatefulWidget {
  const ThreadsPage({super.key});

  @override
  State<ThreadsPage> createState() => _ThreadsPageState();
}

class _ThreadsPageState extends State<ThreadsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThreadProvider>().fetchThreads(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<ThreadProvider>().fetchThreads();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ThreadSocial"),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.user;
              if (user == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(userId: user.id.toString()),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage:
                        (user.profileImage != null &&
                            user.profileImage!.isNotEmpty)
                        ? CachedNetworkImageProvider(
                            '${AppConstants.uploadsUrl}/profiles/${user.profileImage}?v=${context.select<AuthProvider, String>((auth) => auth.cacheBuster)}',
                          )
                        : null,
                    child:
                        (user.profileImage == null ||
                            user.profileImage!.isEmpty)
                        ? Text(
                            user.username.isNotEmpty
                                ? user.username[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<ThreadProvider>().fetchThreads(refresh: true),
        child: Consumer<ThreadProvider>(
          builder: (context, provider, _) {
            if (provider.threads.isEmpty && provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.threads.isEmpty) {
              return const Center(
                child: Text("No threads yet. Be the first to post!"),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: provider.threads.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.threads.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return ThreadCard(thread: provider.threads[index]);
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
