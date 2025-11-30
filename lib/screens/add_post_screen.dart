import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/database/db_helper.dart';
import '../controllers/session_controller.dart';
import '../widgets/AdminBottomNavBar.dart'; // import bottom nav

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final captionCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  File? imageFile;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await Session.getUserId();
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active user found")),
      );
      Navigator.pop(context);
      return;
    }
    setState(() {
      userId = id;
    });
  }

  Future pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          imageFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: $e")),
      );
    }
  }

  Future savePost() async {
    final caption = captionCtrl.text.trim();
    final body = bodyCtrl.text.trim();

    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Caption cannot be empty")),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    try {
      await DBHelper.instance.insertPost(
        userId: userId!,
        caption: caption,
        body: body,
        imagePath: imageFile?.path,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post created successfully")),
      );

      Navigator.pop(context, true); // return true to refresh CommunityScreen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create post: $e")),
      );
    }
  }

  @override
  void dispose() {
    captionCtrl.dispose();
    bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Post")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: captionCtrl,
              decoration: const InputDecoration(labelText: "Caption"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: "Body"),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            imageFile != null
                ? Image.file(imageFile!, height: 200, fit: BoxFit.cover)
                : const Text("No image selected"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Pick Image"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: savePost,
              child: const Text("Post"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(
        currentIndex: 3, // Assuming posts tab
      ),
    );
  }
}
