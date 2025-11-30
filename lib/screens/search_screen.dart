import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/header_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../controllers/database/db_helper.dart';
import 'bookdetail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Map<String, dynamic>> allBooks = [];
  List<Map<String, dynamic>> filteredBooks = [];
  List<String> topTags = [];
  String searchQuery = "";
  Map<String, dynamic>? activeUser;

  @override
  void initState() {
    super.initState();
    loadActiveUserAndBooks();
  }

  Future<void> loadActiveUserAndBooks() async {
    activeUser = await DBHelper.instance.getActiveUser();
    await loadBooks();
  }

  Future<void> loadBooks() async {
    // Fetch all books (optionally could filter by user if needed)
    final books = await DBHelper.instance.getBooks();

    setState(() {
      allBooks = books;
      filteredBooks = books;
      topTags = extractTopTags(books);
    });
  }

  // Extract most common tags from comma-separated strings
  List<String> extractTopTags(List<Map<String, dynamic>> books) {
    Map<String, int> tagCount = {};

    for (var book in books) {
      final tagString = (book["tags"] ?? "").toString().trim();
      if (tagString.isEmpty) continue;

      final tags = tagString
          .split(",")
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty)
          .toList();

      for (var t in tags) {
        tagCount[t] = (tagCount[t] ?? 0) + 1;
      }
    }

    final sorted = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => e.key).take(10).toList();
  }

  void performSearch(String query) {
    final q = query.toLowerCase();

    setState(() {
      searchQuery = query;

      if (q.isEmpty) {
        filteredBooks = allBooks;
        return;
      }

      filteredBooks = allBooks.where((book) {
        final title = book['title'].toString().toLowerCase();
        final author = book['author'].toString().toLowerCase();
        final tags = book['tags'].toString().toLowerCase();

        return title.contains(q) || author.contains(q) || tags.contains(q);
      }).toList();
    });
  }

  void searchByTag(String tag) {
    performSearch(tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderSection(),
            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: performSearch,
                decoration: InputDecoration(
                  hintText: "Search books, authors, tags...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Top Tags
            if (topTags.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: topTags.map((tag) {
                    return GestureDetector(
                      onTap: () => searchByTag(tag),
                      child: Chip(
                        label: Text(tag),
                        backgroundColor: Colors.blue.shade100,
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 12),

            // Search Results
            Expanded(
              child: filteredBooks.isEmpty
                  ? const Center(
                child: Text(
                  "No books found",
                  style: TextStyle(fontSize: 18),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  final book = filteredBooks[index];
                  final Uint8List coverBytes = book['cover'];
                  final title = book['title'];
                  final author = book['author'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetailPage(book: book),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              coverBytes,
                              height: 90,
                              width: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  author,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}
