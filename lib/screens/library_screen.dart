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
  List<Map<String, dynamic>> myUploadedBooks = [];
  List<Map<String, dynamic>> sections = [];
  Map<int, List<Map<String, dynamic>>> sectionBooks = {};

  @override
  void initState() {
    super.initState();
    fetchLibrary();
  }

  Future<void> fetchLibrary() async {
    try {
      final fetchedAll = await DBHelper.instance.getAllBooks();
      final userBooks = await DBHelper.instance.getMyBooks();
      final sec = await DBHelper.instance.getSections();

      Map<int, List<Map<String, dynamic>>> secBooks = {};
      for (var s in sec) {
        final booksInSection = await DBHelper.instance.getBooksInSection(s['id'] as int);
        secBooks[s['id'] as int] = booksInSection;
      }

      setState(() {
        allBooks = fetchedAll;
        myUploadedBooks = userBooks;
        sections = sec;
        sectionBooks = secBooks;
      });
    } catch (e, st) {
      debugPrint("fetchLibrary error: $e\n$st");
    }
  }

  void deleteBook(int bookId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DBHelper.instance.deleteBook(bookId);
        await fetchLibrary();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book deleted')));
        }
      } catch (e) {
        debugPrint("deleteBook error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete book')));
        }
      }
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (name.trim().isNotEmpty) {
                await DBHelper.instance.insertSection(name.trim());
                await fetchLibrary();
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
    final TextEditingController searchController = TextEditingController();
    final ValueNotifier<String> query = ValueNotifier("");

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: SizedBox(width: 48, child: Divider(thickness: 4))),
                const SizedBox(height: 6),
                const Center(child: Text("Add Book to Section", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  onChanged: (value) => query.value = value.toLowerCase(),
                  decoration: InputDecoration(
                    hintText: "Search book...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: query,
                    builder: (context, value, _) {
                      final filtered = allBooks.where((b) {
                        final notAdded = !(sectionBooks[sectionId]?.any((sb) => sb['id'] == b['id']) ?? false);
                        final matches = b['title'].toString().toLowerCase().contains(value.toLowerCase());
                        return notAdded && matches;
                      }).toList();

                      if (filtered.isEmpty) return const Center(child: Text("No books found"));

                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final book = filtered[i];
                          final Uint8List? coverBytes = book['cover'] as Uint8List?;
                          return ListTile(
                            leading: coverBytes != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.memory(coverBytes, width: 45, height: 60, fit: BoxFit.cover))
                                : Container(width: 45, height: 60, color: Colors.grey[300]),
                            title: Text(book['title'] ?? "Untitled"),
                            subtitle: Text(book['author'] ?? ""),
                            onTap: () async {
                              try {
                                await DBHelper.instance.addBookToSection(sectionId, book['id'] as int);
                                setState(() {
                                  final updatedBooks = List<Map<String, dynamic>>.from(sectionBooks[sectionId] ?? []);
                                  updatedBooks.add(book);
                                  sectionBooks[sectionId] = updatedBooks;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Book added to section')),
                                  );
                                }
                                Navigator.pop(context);
                              } catch (e) {
                                debugPrint("addBookToSection error: $e");
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to add book to section')),
                                  );
                                }
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void editBook(Map<String, dynamic> book) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditBookScreen(book: book, onSave: fetchLibrary)));
  }

  Widget buildBookCard(Map<String, dynamic> book, {bool showEditDelete = true, VoidCallback? onDelete, bool isSectionBook = false}) {
    final Uint8List coverBytes = book['cover'];

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(book: book, activeUser: widget.activeUser)));
            },
            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(coverBytes, height: 170, width: 140, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 20,
            child: Text(book['title'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 2),
          if (showEditDelete && onDelete != null)
            Row(
              children: [
                if (!isSectionBook)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => editBook(book),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text("Edit", style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                if (!isSectionBook) const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDelete,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(isSectionBook ? "Remove" : "Delete", style: const TextStyle(fontSize: 12, color: Colors.white)),
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("My Uploaded Books", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 260,
                child: myUploadedBooks.isEmpty
                    ? const Center(child: Text("No books uploaded yet"))
                    : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: myUploadedBooks.length,
                  itemBuilder: (context, index) => buildBookCard(
                    myUploadedBooks[index],
                    showEditDelete: true,
                    onDelete: () => deleteBook(myUploadedBooks[index]['id'] as int),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Sections", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add), onPressed: addSection),
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
                            Text(sec['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                IconButton(onPressed: () => addBookToSectionPopup(secId), icon: const Icon(Icons.add)),
                                IconButton(
                                  onPressed: () async {
                                    bool? confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete Section'),
                                        content: Text('Are you sure you want to delete "${sec['name']}"?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await DBHelper.instance.database.then((db) => db.delete('sections', where: 'id = ?', whereArgs: [secId]));
                                      fetchLibrary();
                                    }
                                  },
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 260,
                        child: booksInSec.isEmpty
                            ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("No books in this section"))
                            : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: booksInSec.length,
                          itemBuilder: (context, index) {
                            final book = booksInSec[index];
                            return buildBookCard(
                              book,
                              showEditDelete: true,
                              isSectionBook: true,
                              onDelete: () async {
                                await DBHelper.instance.removeBookFromSection(secId, book['id'] as int);
                                setState(() {
                                  sectionBooks[secId] = List<Map<String, dynamic>>.from(sectionBooks[secId] ?? [])..remove(book);
                                });
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
