import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';   // ✅ File picker
import '../controllers/database/db_helper.dart';
import 'reader_screen.dart';
import '../widgets/AdminHeader_bar.dart';        // ✅ Admin Header

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

  Future<void> pickCover() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() async => coverBytes = await pickedFile.readAsBytes());
  }
  }

  /// ✅ PICK & REPLACE EPUB/PDF FILE
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      filePathController.text = result.files.single.path!;
      setState(() {});
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
      Navigator.pop(context);
    }
  }

  void deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.deleteBook(widget.book['id']);
      Navigator.pop(context);
    }
  }

  void openReader() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          filePath: filePathController.text,
          title: titleController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔵 Admin Header
          const AdminHeaderSection(),

          /// 🔙 Back Arrow + Title
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
                  "Edit Book",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
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
                      /// 📚 Cover Image Picker
                      GestureDetector(
                        onTap: pickCover,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: coverBytes != null
                              ? MemoryImage(coverBytes!)
                              : const AssetImage(
                              'assets/book_placeholder.jpg')
                          as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Title required' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: summaryController,
                        decoration: const InputDecoration(labelText: 'Summary'),
                        maxLines: 3,
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Summary required' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: authorController,
                        decoration: const InputDecoration(labelText: 'Author'),
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Author required' : null,
                      ),
                      const SizedBox(height: 12),

                      /// 📂 FILE PICKER (EPUB/PDF)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: filePathController,
                              decoration: const InputDecoration(labelText: 'File Path'),
                              validator: (v) =>
                              v == null || v.trim().isEmpty ? 'File required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: pickFile,
                            child: const Text('Change File'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma separated)',
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: deleteBook,
                            child: const Text('Delete Book'),
                          ),

                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: openReader,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Read'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: saveChanges,
                                child: const Text('Save Changes'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
