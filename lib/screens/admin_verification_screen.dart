import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../controllers/database/db_helper.dart';
import '../widgets/AdminBottomNavBar.dart';
import '../widgets/AdminHeader_bar.dart';
import 'bookdetail_screen.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  List<Map<String, dynamic>> pendingBooks = [];
  List<Map<String, dynamic>> approvedBooks = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => isLoading = true);
    final pending = await DBHelper.instance.getPendingBooks();
    final allApproved = await DBHelper.instance.getAllBooks();
    setState(() {
      pendingBooks = pending;
      approvedBooks = allApproved;
      isLoading = false;
    });
  }

  Future<void> _approveBook(int bookId, int userId, String bookTitle) async {
    try {
      await DBHelper.instance.approveBook(bookId);

      // Send notification to uploader
      await DBHelper.instance.addNotification(
        userId: userId,
        title: "Book Approved",
        message: "Your book \"$bookTitle\" has been verified and uploaded!",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book approved successfully!')),
      );

      _loadBooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving book: $e')),
      );
    }
  }

  Future<void> _rejectBook(int bookId, int userId, String bookTitle) async {
    try {
      await DBHelper.instance.deleteBook(bookId);

      // Send notification to uploader
      await DBHelper.instance.addNotification(
        userId: userId,
        title: "Book Rejected",
        message: "Your book \"$bookTitle\" has been rejected by the admin.",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book rejected successfully!')),
      );

      _loadBooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting book: $e')),
      );
    }
  }

  void _openBookDetails(Map<String, dynamic> book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailPage(book: book),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book,
      {bool showApproveReject = false}) {
    final approved = book['isApproved'] == 1;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                book['cover'] != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    book['cover'] as Uint8List,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                )
                    : Container(
                  width: 80,
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.book, size: 50),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Author: ${book['author'] ?? ''}'),
                      const SizedBox(height: 4),
                      Text(
                        'Tags: ${book['tags'] ?? ''}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _openBookDetails(book),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                  child: const Text(
                    'View Book',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                if (showApproveReject)
                  ElevatedButton(
                    onPressed: approved
                        ? null
                        : () => _approveBook(
                        book['id'], book['userId'], book['title']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      approved ? Colors.green : const Color(0xFF0A1A5C),
                    ),
                    child: Text(
                      approved ? 'Approved' : 'Approve',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                if (showApproveReject) const SizedBox(width: 8),
                if (showApproveReject)
                  ElevatedButton(
                    onPressed: () =>
                        _rejectBook(book['id'], book['userId'], book['title']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AdminHeaderSection(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Pending Verification"),
              Tab(text: "Approved Books"),
            ],
            labelColor: const Color(0xFF0A1A5C),
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                // Pending Verification Tab
                pendingBooks.isEmpty
                    ? const Center(
                    child: Text("No pending books for verification."))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingBooks.length,
                  itemBuilder: (context, index) {
                    final book = pendingBooks[index];
                    return _buildBookCard(book,
                        showApproveReject: true);
                  },
                ),

                // Approved Books Tab
                approvedBooks.isEmpty
                    ? const Center(child: Text("No approved books."))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: approvedBooks.length,
                  itemBuilder: (context, index) {
                    final book = approvedBooks[index];
                    return _buildBookCard(book);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 5),
    );
  }
}
