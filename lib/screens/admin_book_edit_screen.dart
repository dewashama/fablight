import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/database/db_helper.dart';

class AdminBookEditScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const AdminBookEditScreen({super.key, required this.book});

  @override
  State<AdminBookEditScreen> createState() => _AdminBookEditScreenState();
}

class _AdminBookEditScreenState extends State<AdminBookEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController summaryController;
  late TextEditingController authorController;
  late TextEditingController filePathController;
  late TextEditingController tagsController;
  Uint8List? coverBytes;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.book['title']);
    summaryController = TextEditingController(text: widget.book['summary']);
    authorController = TextEditingController(text: widget.book['author']);
    filePathController = TextEditingController(text: widget.book['filePath']);
    tagsController = TextEditingController(text: widget.book['tags'] ?? '');
    coverBytes = widget.book['cover'];
  }

  @override
  void dispose() {
    titleController.dispose();
    summaryController.dispose();
    authorController.dispose();
    filePathController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  Future<void> pickCover() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        coverBytes = bytes;
      });
    }
  }

  void saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedBook = {
        'title': titleController.text.trim(),
        'summary': summaryController.text.trim(),
        'author': authorController.text.trim(),
        'filePath': filePathController.text.trim(),
        'tags': tagsController.text.trim(),
        'cover': coverBytes,
      };

      await DBHelper.instance.updateBook(widget.book['id'], updatedBook);
      Navigator.pop(context); // Back to search list
    }
  }

  void deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book?'),
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
      await DBHelper.instance.deleteBook(widget.book['id']);
      Navigator.pop(context); // Back to search list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Book'),
        backgroundColor: const Color(0xFF2929BB),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickCover,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: coverBytes != null
                        ? MemoryImage(coverBytes!)
                        : const AssetImage('assets/book_placeholder.jpg')
                    as ImageProvider,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Title required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: summaryController,
                  decoration: const InputDecoration(labelText: 'Summary'),
                  maxLines: 3,
                  validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Summary required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: authorController,
                  decoration: const InputDecoration(labelText: 'Author'),
                  validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Author required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: filePathController,
                  decoration: const InputDecoration(labelText: 'File Path'),
                  validator: (val) =>
                  val == null || val.trim().isEmpty ? 'File path required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tagsController,
                  decoration:
                  const InputDecoration(labelText: 'Tags (comma separated)'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: deleteBook,
                      child: const Text('Delete Book'),
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
    );
  }
}
