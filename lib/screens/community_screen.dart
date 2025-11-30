import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../controllers/database/db_helper.dart';
import '../controllers/session_controller.dart';
import '../models/post.dart';
import '../widgets/header_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import 'add_post_screen.dart';
import 'postview_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Map<String, dynamic>> postsWithUser = [];
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadSessionAndPosts();
  }

  Future<void> _loadSessionAndPosts() async {
    currentUserId = await Session.getUserId();
    await loadPosts();
  }

  Future<void> loadPosts() async {
    // Fetch all posts including user info
    postsWithUser = await DBHelper.instance.getPosts();

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const HeaderSection(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Community Posts",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      if (currentUserId == null) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddPostScreen()),
                      );
                      if (!mounted) return;
                      await loadPosts();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: postsWithUser.isEmpty
                  ? const Center(child: Text("No posts yet"))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: postsWithUser.length,
                itemBuilder: (context, index) {
                  final p = postsWithUser[index];
                  Uint8List? profilePic = p['profilePic'];

                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostViewScreen(post: Post.fromMap(p)),
                        ),
                      );
                      if (!mounted) return;
                      await loadPosts();
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // USER INFO ROW
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: profilePic != null
                                      ? MemoryImage(profilePic)
                                      : const AssetImage("assets/profile.jpg") as ImageProvider,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  p['username'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // POST IMAGE
                          if (p['imagePath'].toString().isNotEmpty)
                            Image.file(
                              File(p['imagePath']),
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),

                          // POST CAPTION & LIKES
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p['caption'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Text("${p['likes']} likes"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
