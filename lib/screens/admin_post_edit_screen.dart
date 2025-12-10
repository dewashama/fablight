import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/database/db_helper.dart';
import '../widgets/AdminBottomNavBar.dart';
import '../widgets/AdminHeader_bar.dart';

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
  List<String> postImages = []; // now a list for multi-image posts

  @override
  void initState() {
    super.initState();
    captionController = TextEditingController(text: widget.post['caption']);
    bodyController = TextEditingController(text: widget.post['body']);

    // Initialize post images list
    final img = widget.post['imagePath'];
    if (img != null && img is String && img.isNotEmpty) {
      postImages = [img];
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        postImages.add(pickedFile.path);
      });
    }
  }

  void saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedPost = {
        'caption': captionController.text.trim(),
        'body': bodyController.text.trim(),
      };

      await DBHelper.instance.updatePostWithImages(
        postId: widget.post['id'],
        postValues: updatedPost,
        imagePaths: postImages,
      );

      if (!mounted) return;
      Navigator.pop(context);
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.deletePostWithImages(widget.post['id']);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void removeImage(int index) {
    setState(() {
      postImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminHeaderSection(),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                const Text(
                  "Edit Post",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      /// Multi-image preview
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: postImages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == postImages.length) {
                              // Add image button
                              return GestureDetector(
                                onTap: pickImage,
                                child: Container(
                                  width: 150,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add, size: 50),
                                  ),
                                ),
                              );
                            }

                            final imgPath = postImages[index];
                            return Stack(
                              children: [
                                Container(
                                  width: 150,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: FileImage(File(imgPath)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 20, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: captionController,
                        decoration:
                        const InputDecoration(labelText: 'Caption'),
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
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white),
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
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
    );
  }
}
