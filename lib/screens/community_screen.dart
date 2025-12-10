import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
  Map<int, int> carouselIndexes = {}; // Track carousel index for each post

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

                  // Split images if multiple paths exist
                  List<String> imagePaths = [];
                  if (p['imagePath'] != null && p['imagePath'].toString().isNotEmpty) {
                    // If stored as comma-separated string of paths
                    imagePaths = p['imagePath'].toString().split(',');
                  }

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

                          // POST IMAGES CAROUSEL
                          if (imagePaths.isNotEmpty)
                            Column(
                              children: [
                                CarouselSlider.builder(
                                  itemCount: imagePaths.length,
                                  itemBuilder: (context, imgIndex, realIndex) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(imagePaths[imgIndex]),
                                        width: double.infinity,
                                        height: 250,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                  options: CarouselOptions(
                                    height: 250,
                                    viewportFraction: 1,
                                    enableInfiniteScroll: false,
                                    onPageChanged: (carouselIndex, reason) {
                                      setState(() {
                                        carouselIndexes[index] = carouselIndex;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Dots Indicator
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(imagePaths.length, (dotIndex) {
                                    return Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (carouselIndexes[index] ?? 0) == dotIndex
                                            ? Colors.blue
                                            : Colors.grey.shade300,
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 8),
                              ],
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
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}
