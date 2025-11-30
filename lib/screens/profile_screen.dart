import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/database/db_helper.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> userPosts = [];
  Uint8List? profileImageBytes;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchUserPosts();
  }

  Future<void> fetchUserData() async {
    final activeUser = await DBHelper.instance.getUserById(widget.userId);
    if (activeUser != null) {
      setState(() {
        user = activeUser;
        nameController.text = activeUser['name'] ?? '';
        usernameController.text = activeUser['username'] ?? '';
        profileImageBytes = activeUser['profilePic'];
      });
    }
  }

  Future<void> fetchUserPosts() async {
    final posts = await DBHelper.instance.getPostsByUser(widget.userId);
    setState(() {
      userPosts = posts;
    });
  }

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        profileImageBytes = bytes;
      });
    }
  }

  Future<void> saveProfile() async {
    if (user == null) return;

    await DBHelper.instance.updateProfile(
      id: user!['id'],
      name: nameController.text,
      username: usernameController.text,
      profilePic: profileImageBytes,
    );

    fetchUserData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        ),
        title: const Text("Profile"),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickProfileImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImageBytes != null
                    ? MemoryImage(profileImageBytes!)
                    : null,
                child: profileImageBytes == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: saveProfile,
              child: const Text("Save Profile"),
            ),
            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Your Posts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            if (userPosts.isEmpty)
              const Text("You haven't made any posts yet."),

            ...userPosts.map((post) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(post['caption']),
                  subtitle: post['body'] != null && post['body'].isNotEmpty
                      ? Text(post['body'])
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editPost(post),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePost(post['id']),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EDIT POST
  // ============================================================

  void _editPost(Map<String, dynamic> post) {
    final captionController = TextEditingController(text: post['caption']);
    final bodyController = TextEditingController(text: post['body']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: captionController,
              decoration: const InputDecoration(labelText: "Caption"),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: "Body"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBHelper.instance.updatePost(
                post['id'],
                {
                  "caption": captionController.text,
                  "body": bodyController.text,
                },
              );

              await fetchUserPosts();

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE POST
  // ============================================================

  void _deletePost(int postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.deletePost(postId);
      fetchUserPosts();
    }
  }
}
