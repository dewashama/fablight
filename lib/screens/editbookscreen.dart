import 'package:flutter/material.dart';
import '../controllers/database/db_helper.dart';

class EditBookScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final VoidCallback onSave;

  const EditBookScreen({super.key, required this.book, required this.onSave});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  late TextEditingController titleController;
  late TextEditingController authorController;
  late TextEditingController summaryController;
  late TextEditingController tagsController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.book['title']);
    authorController = TextEditingController(text: widget.book['author']);
    summaryController = TextEditingController(text: widget.book['summary']);
    tagsController = TextEditingController(text: widget.book['tags']);
  }

  void saveChanges() async {
    final activeUserId = await DBHelper.instance.getActiveUserId();

    if (activeUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to edit a book")),
      );
      return;
    }

    if (activeUserId != widget.book['userId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot edit a book you didn't upload")),
      );
      return;
    }

    await DBHelper.instance.database.then((db) {
      db.update(
        'books',
        {
          'title': titleController.text,
          'author': authorController.text,
          'summary': summaryController.text,
          'tags': tagsController.text,
        },
        where: 'id = ?',
        whereArgs: [widget.book['id']],
      );
    });

    widget.onSave();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Book')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(labelText: 'Author'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: summaryController,
              decoration: const InputDecoration(labelText: 'Summary'),
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveChanges,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
