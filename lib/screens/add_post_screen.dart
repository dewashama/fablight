import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/database/db_helper.dart';
import '../controllers/session_controller.dart';
import '../widgets/AdminBottomNavBar.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final captionCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();

  List<File> imageFiles = []; // 🔥 MULTIPLE images
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await Session.getUserId();
    if (id == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No active user found")));
      Navigator.pop(context);
      return;
    }
    setState(() {
      userId = id;
    });
  }

  /// 🔥 Pick MULTIPLE images
  Future pickImages() async {
    try {
      final pickedList = await ImagePicker().pickMultiImage();

      if (pickedList.isNotEmpty) {
        setState(() {
          imageFiles = pickedList.map((x) => File(x.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to pick images: $e")));
    }
  }

  Future savePost() async {
    final caption = captionCtrl.text.trim();
    final body = bodyCtrl.text.trim();

    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Caption cannot be empty")));
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")));
      return;
    }

    /// 🔥 Save MULTIPLE image paths as a single string (comma separated)
    final imagePaths = imageFiles.isNotEmpty
        ? imageFiles.map((f) => f.path).join(',')
        : null;

    try {
      await DBHelper.instance.insertPost(
        userId: userId!,
        caption: caption,
        body: body,
        imagePath: imagePaths, // 🔥 stores multiple images
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post created successfully")));

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to create post: $e")));
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
            /// Caption
            TextField(
              controller: captionCtrl,
              decoration: const InputDecoration(labelText: "Caption"),
            ),
            const SizedBox(height: 10),

            /// Body
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: "Body"),
              maxLines: 3,
            ),
            const SizedBox(height: 10),

            /// 🔥 Display multiple selected images
            if (imageFiles.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageFiles.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(imageFiles[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        /// ❌ Remove image button
                        Positioned(
                          right: 18,
                          top: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                imageFiles.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            else
              const Text("No images selected"),

            const SizedBox(height: 10),

            /// 🔵 Pick Multiple Images Button
            ElevatedButton(
              onPressed: pickImages,
              child: const Text("Pick Images"),
            ),

            const SizedBox(height: 10),

            /// Submit
            ElevatedButton(
              onPressed: savePost,
              child: const Text("Post"),
            ),
          ],
        ),
      ),

      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
    );
  }
}
