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
  final TextEditingController tagInputCtrl = TextEditingController();

  XFile? bookCover;
  Uint8List? bookCoverBytes;
  String? bookFilePath;

  final ImagePicker _picker = ImagePicker();
  final List<String> tags = [];

  int? currentUserId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final id = await Session.getUserId();
    if (id == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    setState(() {
      currentUserId = id;
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
        bookFilePath = result.files.single.path;
      });
    }
  }

  void addTagFromInput() {
    final t = tagInputCtrl.text.trim();
    if (t.isEmpty) return;

    if (!tags.map((e) => e.toLowerCase()).contains(t.toLowerCase())) {
      setState(() => tags.add(t));
    }

    tagInputCtrl.clear();
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

    try {
      await DBHelper.instance.insertBook(
        userId: currentUserId!,        // <-- ADDED
        title: titleController.text,
        summary: summaryController.text,
        author: authorController.text,
        coverBytes: bookCoverBytes!,
        filePath: bookFilePath!,
        tags: tags.join(','),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book added successfully!')),
      );

      setState(() {
        titleController.clear();
        summaryController.clear();
        authorController.clear();
        bookCover = null;
        bookCoverBytes = null;
        bookFilePath = null;
        tags.clear();
        tagInputCtrl.clear();
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
    tagInputCtrl.dispose();
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
            // ---------------- Back Arrow + Title ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
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

            // ---------------- Form ----------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Cover Picker
                    GestureDetector(
                      onTap: pickCoverImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: bookCoverBytes != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(bookCoverBytes!, fit: BoxFit.cover),
                        )
                            : const Center(child: Text('Tap to select book cover')),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary
                    TextField(
                      controller: summaryController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Summary',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Author
                    TextField(
                      controller: authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    Text(
                      "Tags (press Add or Enter to add)",
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tagInputCtrl,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => addTagFromInput(),
                            decoration: const InputDecoration(
                              hintText: 'e.g. fantasy, classic, poetry',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: addTagFromInput,
                          child: const Text("Add"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: tags.map((t) {
                        return Chip(
                          label: Text(t),
                          onDeleted: () => removeTag(t),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // File Picker
                    ElevatedButton(
                      onPressed: pickBookFile,
                      child: Text(
                        bookFilePath != null
                            ? 'Selected: ${bookFilePath!.split('/').last}'
                            : 'Upload PDF/EPUB',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitBook,
                        child: const Text('Add Book'),
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
