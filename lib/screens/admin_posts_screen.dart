import 'package:flutter/material.dart';
import '../controllers/database/db_helper.dart';
import 'admin_post_edit_screen.dart';
import '../widgets/AdminBottomNavBar.dart';

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> filteredPosts = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final res = await DBHelper.instance.getPosts();
    setState(() {
      posts = res;
      filteredPosts = res;
    });
  }

  void searchPosts(String query) {
    final filtered = posts.where((post) {
      final caption = (post['caption'] ?? '').toString().toLowerCase();
      final body = (post['body'] ?? '').toString().toLowerCase();
      final user = (post['username'] ?? '').toString().toLowerCase();
      final q = query.toLowerCase();
      return caption.contains(q) || body.contains(q) || user.contains(q);
    }).toList();

    setState(() {
      filteredPosts = filtered;
    });
  }

  void deletePost(int postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.deletePost(postId);
      fetchPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // removes the back arrow
        backgroundColor: const Color(0xFF2929BB),
        title: const Text(
          'Admin Posts',
          style: TextStyle(color: Colors.white), // header text white
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search posts by user, caption, or body',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: searchPosts,
            ),
          ),
          Expanded(
            child: filteredPosts.isEmpty
                ? const Center(child: Text("No posts found"))
                : ListView.builder(
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: post['profilePic'] != null
                        ? CircleAvatar(
                      backgroundImage: MemoryImage(post['profilePic']),
                    )
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(post['caption'] ?? ''),
                    subtitle: Text('By: ${post['username'] ?? 'Unknown'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminPostEditScreen(post: post),
                              ),
                            ).then((_) => fetchPosts());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deletePost(post['id']),
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
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3), // Posts index
    );
  }
}
