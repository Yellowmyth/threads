import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'threads_page.dart';
import 'create_thread_page.dart';
import 'profile_page.dart';
import '../providers/auth_provider.dart';
import '../providers/thread_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/constants.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final List<Widget> pages = [
      const ThreadsPage(),
      const SizedBox(), // Placeholder for the middle button action
      if (user != null)
        ProfilePage(
          key: ValueKey("profile_${user.id}"),
          userId: user.id.toString(),
        )
      else
        const Center(child: Text("Login required")),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex == 1
              ? 0
              : _currentIndex, // Keep Home visible if Create is clicked
          children: pages,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            bool? refreshNeeded = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateThreadPage()),
            );

            if (refreshNeeded == true && context.mounted) {
              // Refresh Home Feed
              context.read<ThreadProvider>().fetchThreads(refresh: true);

              // Refresh Profile if it's currently selected
              final user = context.read<AuthProvider>().user;
              if (user != null) {
                context.read<ProfileProvider>().fetchProfile(
                  user.id.toString(),
                );
              }
            }
          },
          backgroundColor: AppColors.primary,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                    color: _currentIndex == 0 ? AppColors.primary : Colors.grey,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                ),
                const SizedBox(width: 40), // Space for FAB
                IconButton(
                  icon: Icon(
                    _currentIndex == 2 ? Icons.person : Icons.person_outline,
                    color: _currentIndex == 2 ? AppColors.primary : Colors.grey,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
