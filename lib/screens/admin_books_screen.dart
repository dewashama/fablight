import 'package:flutter/material.dart';
import '../controllers/database/db_helper.dart';
import 'admin_book_edit_screen.dart';
import '../widgets/AdminBottomNavBar.dart';
import '../widgets/AdminHeader_bar.dart'; // <-- added

class AdminBookSearchScreen extends StatefulWidget {
  const AdminBookSearchScreen({super.key});

  @override
  State<AdminBookSearchScreen> createState() => _AdminBookSearchScreenState();
}

class _AdminBookSearchScreenState extends State<AdminBookSearchScreen> {
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> filteredBooks = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBooks();
    searchController.addListener(filterBooks);
  }

  @override
  void dispose() {
    searchController.removeListener(filterBooks);
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchBooks() async {
    final allBooks = await DBHelper.instance.getAllBooks();
    setState(() {
      books = allBooks;
      filteredBooks = allBooks;
    });
  }

  void filterBooks() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredBooks = books
          .where((book) =>
          book['title'].toString().toLowerCase().contains(query))
          .toList();
    });
  }

  void openEditScreen(Map<String, dynamic> book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminBookEditScreen(book: book),
      ),
    ).then((_) => fetchBooks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          const AdminHeaderSection(),  // ⭐ NEW HEADER ADDED

          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for a book...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // BOOK LIST
          Expanded(
            child: filteredBooks.isEmpty
                ? const Center(child: Text('No books found'))
                : ListView.builder(
              itemCount: filteredBooks.length,
              itemBuilder: (_, index) {
                final book = filteredBooks[index];
                return ListTile(
                  leading: book['cover'] != null
                      ? CircleAvatar(
                    backgroundImage: MemoryImage(book['cover']),
                  )
                      : const CircleAvatar(child: Icon(Icons.book)),
                  title: Text(book['title']),
                  subtitle: Text(book['author'] ?? ''),
                  onTap: () => openEditScreen(book),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 1),
    );
  }
}
