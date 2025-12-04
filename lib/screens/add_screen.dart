import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../widgets/bottom_nav_bar.dart';
import '../controllers/database/db_helper.dart';
import '../controllers/session_controller.dart';
import '../screens/home_screen.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController summaryController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController tagInputController = TextEditingController();

  XFile? bookCover;
  Uint8List? bookCoverBytes;
  String? bookFilePath;

  final ImagePicker _picker = ImagePicker();
  final List<String> tags = [];

  int? currentUserId;
  String? currentUserRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final id = await Session.getUserId();
    final role = await Session.getUserRole();

    if (id == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    setState(() {
      currentUserId = id;
      currentUserRole = role ?? "user";
      isLoading = false;
    });
  }

  Future<void> pickCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        bookCover = image;
        bookCoverBytes = bytes;
      });
    }
  }

  Future<void> pickBookFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        bookFilePath = result.files.single.path!;
      });
    }
  }

  void addTagFromInput() {
    final t = tagInputController.text.trim();
    if (t.isEmpty) return;

    if (!tags.map((e) => e.toLowerCase()).contains(t.toLowerCase())) {
      setState(() => tags.add(t));
    }

    tagInputController.clear();
  }

  void removeTag(String t) {
    setState(() => tags.remove(t));
  }

  Future<void> submitBook() async {
    if (titleController.text.isEmpty ||
        summaryController.text.isEmpty ||
        authorController.text.isEmpty ||
        bookCoverBytes == null ||
        bookFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and upload files')),
      );
      return;
    }

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in. Please log in first.')),
      );
      return;
    }

    final isApproved = (currentUserRole == "admin") ? 1 : 0;

    try {
      // Insert book with isApproved flag
      final bookId = await DBHelper.instance.insertBook(
        userId: currentUserId!,
        title: titleController.text,
        summary: summaryController.text,
        author: authorController.text,
        coverBytes: bookCoverBytes!,
        filePath: bookFilePath!,
        tags: tags.join(','),
        isApproved: isApproved,
      );

      // Send notifications to admins if user is not admin
      if (currentUserRole != "admin") {
        final admins = await DBHelper.instance.getUsers();
        final adminUsers = admins.where((u) => u['role'] == 'admin').toList();

        print("Admins found: ${adminUsers.length}");
        for (var admin in adminUsers) {
          try {
            final id = await DBHelper.instance.addVerificationNotification(
              userId: admin['id'],
              title: 'Book Verification',
              message: "New book submitted: ${titleController.text}",
            );
            print('Notification added for admin ${admin['id']} with id $id');
          } catch (e) {
            print('Error adding notification for admin ${admin['id']}: $e');
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApproved == 1
                ? 'Book added & automatically approved (Admin).'
                : 'Book submitted! Awaiting admin approval.',
          ),
        ),
      );

      // Clear all input fields
      setState(() {
        titleController.clear();
        summaryController.clear();
        authorController.clear();
        bookCoverBytes = null;
        bookFilePath = null;
        tags.clear();
        tagInputController.clear();
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving book: $e')),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    summaryController.dispose();
    authorController.dispose();
    tagInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Add Book",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: pickCoverImage,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: bookCoverBytes != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            bookCoverBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Center(
                          child: Text(
                            'Tap to select cover image',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Book Title",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: summaryController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Summary",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: authorController,
                      decoration: const InputDecoration(
                        labelText: "Author",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text("Tags"),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tagInputController,
                            onSubmitted: (_) => addTagFromInput(),
                            decoration: const InputDecoration(
                              hintText: "e.g. fantasy, classic",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: addTagFromInput,
                          child: const Text("Add"),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 8,
                      children: tags
                          .map((t) => Chip(
                        label: Text(t),
                        onDeleted: () => removeTag(t),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: pickBookFile,
                      child: Text(
                        bookFilePath == null
                            ? "Upload PDF/EPUB"
                            : "Selected: ${bookFilePath!.split('/').last}",
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitBook,
                        child: const Text("Add Book"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}
