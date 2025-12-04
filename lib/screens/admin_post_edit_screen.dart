import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/database/db_helper.dart';
import '../widgets/AdminBottomNavBar.dart';
import 'admin_posts_screen.dart';

class AdminPostEditScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const AdminPostEditScreen({super.key, required this.post});

  @override
  State<AdminPostEditScreen> createState() => _AdminPostEditScreenState();
}

class _AdminPostEditScreenState extends State<AdminPostEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController captionController;
  late TextEditingController bodyController;
  String? postImagePath; // <-- store image file path

  @override
  void initState() {
    super.initState();
    captionController = TextEditingController(text: widget.post['caption']);
    bodyController = TextEditingController(text: widget.post['body']);
    // initialize image path from DB
    final img = widget.post['imagePath'];
    if (img != null && img is String) postImagePath = img;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        postImagePath = pickedFile.path;
      });
    }
  }

  void saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedPost = {
        'caption': captionController.text.trim(),
        'body': bodyController.text.trim(),
        'imagePath': postImagePath,
      };

      await DBHelper.instance.updatePost(widget.post['id'], updatedPost);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPostsScreen()),
      );
    }
  }

  void deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.deletePost(widget.post['id']);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPostsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        backgroundColor: const Color(0xFF2929BB),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminPostsScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[300],
                      image: postImagePath != null
                          ? DecorationImage(
                        image: FileImage(File(postImagePath!)),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: postImagePath == null
                        ? const Center(
                        child:
                        Icon(Icons.image, size: 50, color: Colors.grey))
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: captionController,
                  decoration: const InputDecoration(labelText: 'Caption'),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Caption required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bodyController,
                  decoration: const InputDecoration(labelText: 'Body'),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: deletePost,
                      child: const Text('Delete Post'),
                    ),
                    ElevatedButton(
                      onPressed: saveChanges,
                      child: const Text('Save Changes'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(
        currentIndex: 3, // Posts tab
      ),
    );
  }

}
