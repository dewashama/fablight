import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/database/db_helper.dart';
import '../widgets/AdminBottomNavBar.dart';

class AdminAddNoticeScreen extends StatefulWidget {
  const AdminAddNoticeScreen({super.key});

  @override
  State<AdminAddNoticeScreen> createState() => _AdminAddNoticeScreenState();
}

class _AdminAddNoticeScreenState extends State<AdminAddNoticeScreen> {
  final DBHelper dbHelper = DBHelper.instance;
  final Map<int, Uint8List?> _images = {}; // slot -> image

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    final notices = await dbHelper.getNotices();
    setState(() {
      for (var notice in notices) {
        int slot = notice['slot'] as int;
        Uint8List? image = notice['image'] as Uint8List?;
        _images[slot] = image;
      }
    });
  }

  Future<void> _pickImage(int slot) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _images[slot] = bytes;
      });
    }
  }

  Future<void> _saveImage(int slot) async {
    if (_images[slot] != null) {
      await dbHelper.addOrUpdateNotice(slot, _images[slot]!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Slot $slot updated successfully!')),
      );
    }
  }

  Widget _buildSlot(int slot) {
    return Card(
      elevation: 3,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickImage(slot),
            child: Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[300],
              child: _images[slot] != null
                  ? Image.memory(
                _images[slot]!,
                fit: BoxFit.cover,
              )
                  : const Center(child: Icon(Icons.add_a_photo, size: 50)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _saveImage(slot),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // removes top back arrow
        backgroundColor: const Color(0xFF0A1A5C),
        title: const Text(
          'Add Notices',
          style: TextStyle(color: Colors.white), // white header text
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            _buildSlot(1),
            const SizedBox(height: 12),
            _buildSlot(2),
            const SizedBox(height: 12),
            _buildSlot(3),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 2), // Center notice button
    );
  }
}
