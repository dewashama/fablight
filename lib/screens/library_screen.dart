import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/header_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../controllers/database/db_helper.dart';
import 'bookdetail_screen.dart';
import 'editbookscreen.dart';

class LibraryScreen extends StatefulWidget {
  final Map<String, dynamic> activeUser;

  const LibraryScreen({super.key, required this.activeUser});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Map<String, dynamic>> allBooks = [];
  List<Map<String, dynamic>> sections = [];
  Map<int, List<Map<String, dynamic>>> sectionBooks = {};

  @override
  void initState() {
    super.initState();
    fetchLibrary();
  }

  Future<void> fetchLibrary() async {
    final userBooks = await DBHelper.instance.getMyBooks();
    final sec = await DBHelper.instance.getSections();

    Map<int, List<Map<String, dynamic>>> secBooks = {};
    for (var s in sec) {
      final booksInSection =
      await DBHelper.instance.getBooksInSection(s['id'] as int);
      secBooks[s['id'] as int] = booksInSection
          .where((b) => b['userId'] == widget.activeUser['id'])
          .toList();
    }

    setState(() {
      allBooks = userBooks;
      sections = sec;
      sectionBooks = secBooks;
    });
  }

  void deleteBook(int bookId) async {
    bool? confirm = await showDialog<bool>(
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DBHelper.instance.database;
      await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
      fetchLibrary();
    }
  }

  void addSection() async {
    String name = '';
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Section'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Section name'),
          onChanged: (val) => name = val,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (name.trim().isNotEmpty) {
                await DBHelper.instance.insertSection(name.trim());
                fetchLibrary();
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void addBookToSectionPopup(int sectionId) async {
    List<Map<String, dynamic>> booksNotInSection = allBooks
        .where((b) =>
    !(sectionBooks[sectionId]?.any((sb) => sb['id'] == b['id']) ??
        false))
        .toList();

    String search = '';
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Book to Section'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                      hintText: 'Search books',
                      prefixIcon: Icon(Icons.search)),
                  onChanged: (val) => setState(() => search = val.toLowerCase()),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: booksNotInSection
                      .where((b) => b['title']
                      .toString()
                      .toLowerCase()
                      .contains(search))
                      .isEmpty
                      ? const Center(child: Text('No books found'))
                      : ListView(
                    shrinkWrap: true,
                    children: booksNotInSection
                        .where((b) => b['title']
                        .toString()
                        .toLowerCase()
                        .contains(search))
                        .map((book) => ListTile(
                      title: Text(book['title']),
                      subtitle: Text(book['author']),
                      onTap: () async {
                        await DBHelper.instance
                            .addBookToSection(
                            sectionId, book['id'] as int);
                        fetchLibrary();
                        Navigator.pop(context);
                      },
                    ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ],
        ),
      ),
    );
  }

  void editBook(Map<String, dynamic> book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBookScreen(
          book: book,
          onSave: fetchLibrary,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // UPDATED BOOK CARD (Taller, wider, safe spacing)
  // -------------------------------------------------------------------------
  Widget buildBookCard(Map<String, dynamic> book,
      {bool showEditDelete = true, VoidCallback? onDelete}) {
    final Uint8List coverBytes = book['cover'];

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookDetailPage(
                    book: book,
                    activeUser: widget.activeUser,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                coverBytes,
                height: 170,
                width: 140,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 20,
            child: Text(
              book['title'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 0.001),
          if (showEditDelete)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => editBook(book),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text(
                      "Edit",
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                    onDelete ?? () => deleteBook(book['id'] as int),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight),
          child: ListView(
            padding: const EdgeInsets.only(top: 10),
            children: [
              const HeaderSection(),
              const SizedBox(height: 16),

              // My Uploaded Books
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "My Uploaded Books",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 260,
                child: allBooks.isEmpty
                    ? const Center(child: Text("No books uploaded yet"))
                    : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allBooks.length,
                  itemBuilder: (context, index) {
                    return buildBookCard(allBooks[index]);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sections",
                      style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: addSection,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              ...sections.map((sec) {
                final secId = sec['id'] as int;
                final booksInSec = sectionBooks[secId] ?? [];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sec['name'],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      addBookToSectionPopup(secId),
                                  icon: const Icon(Icons.add),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    bool? confirm =
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete Section'),
                                        content: Text(
                                            'Are you sure you want to delete "${sec['name']}"?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child:
                                              const Text('Cancel')),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final db =
                                      await DBHelper.instance.database;
                                      await db.delete('sections',
                                          where: 'id ?', whereArgs: [secId]);
                                      fetchLibrary();
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 260,
                        child: booksInSec.isEmpty
                            ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("No books in this section"),
                        )
                            : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: booksInSec.length,
                          itemBuilder: (context, index) {
                            final book = booksInSec[index];
                            return buildBookCard(
                              book,
                              showEditDelete: true,
                              onDelete: () async {
                                await DBHelper.instance
                                    .removeBookFromSection(
                                    secId, book['id'] as int);
                                fetchLibrary();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
