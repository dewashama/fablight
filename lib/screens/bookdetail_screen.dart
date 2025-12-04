import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../controllers/database/db_helper.dart';
import '../widgets/bottom_nav_bar.dart';
import '../screens/home_screen.dart';
import 'reader_screen.dart';

class BookDetailPage extends StatefulWidget {
  final Map<String, dynamic> book;
  final Map<String, dynamic>? activeUser;

  const BookDetailPage({
    super.key,
    required this.book,
    this.activeUser,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  List<Map<String, dynamic>> reviews = [];
  int rating = 0;
  final TextEditingController reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final res = await DBHelper.instance.getReviews(widget.book['id']);
    if (!mounted) return;
    setState(() {
      reviews = res;
    });
  }

  Future<void> submitReview() async {
    final text = reviewController.text.trim();
    final user = widget.activeUser ?? await DBHelper.instance.getActiveUser();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in")),
      );
      return;
    }

    final userId = user["id"];
    if (rating == 0 && text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating or review')),
      );
      return;
    }

    await DBHelper.instance.addReview(
      bookId: widget.book['id'],
      userId: userId,
      rating: rating,
      review: text,
    );

    if (!mounted) return;
    reviewController.clear();
    setState(() {
      rating = 0;
    });
    await fetchReviews();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted successfully')),
    );
  }

  Future<void> downloadBook() async {
    final path = widget.book['filePath'];
    final file = File(path);

    if (await file.exists()) {
      final dir = await getApplicationDocumentsDirectory();
      final newPath = '${dir.path}/${file.uri.pathSegments.last}';
      await file.copy(newPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book downloaded to $newPath')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book file not found')),
      );
    }
  }

  List<String> parseTags(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List cover = widget.book['cover'];
    final String title = widget.book['title'];
    final String author = widget.book['author'];
    final String summary = widget.book['summary'];
    final tags = parseTags(widget.book['tags'] ?? "");

    final isUploader = widget.activeUser != null &&
        widget.activeUser!['id'] == widget.book['uploaderId'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    "Book Detail",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (isUploader)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {},
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          cover,
                          height: 200,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("by $author",
                        style: const TextStyle(
                            fontSize: 16, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),

                    if (tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: tags.map((e) => Chip(label: Text(e))).toList(),
                      ),

                    const SizedBox(height: 16),
                    const Text("Summary",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(summary),
                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: downloadBook,
                          child: const Text("Download Book"),
                        ),
                        const SizedBox(width: 16),

                        // 🔥 Integrated Read Button Logic
                        ElevatedButton(
                          onPressed: () async {
                            final String? path = widget.book['filePath'];

                            if (path == null || path.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Book file not available')),
                              );
                              return;
                            }

                            final file = File(path);

                            if (!await file.exists()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("File does not exist at path:\n$path"),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReaderScreen(filePath: path, title: '',),
                              ),
                            );
                          },
                          child: const Text("Read Book"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Rating
                    const Text("Rate this book",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(index < rating
                              ? Icons.star
                              : Icons.star_border),
                          color: Colors.amber,
                          onPressed: () {
                            setState(() {
                              rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),

                    TextField(
                      controller: reviewController,
                      decoration: const InputDecoration(
                        labelText: "Write a review",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 8),
                    ElevatedButton(
                        onPressed: submitReview,
                        child: const Text("Submit Review")),
                    const SizedBox(height: 20),

                    const Text("Reviews",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    if (reviews.isEmpty) const Text("No reviews yet"),

                    Column(
                      children: reviews.map((r) {
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundImage: r["profilePic"] != null
                                ? MemoryImage(r["profilePic"])
                                : null,
                            child: r["profilePic"] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(r["username"] ?? "Unknown User"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(r['rating'],
                                        (i) => const Icon(Icons.star,
                                        color: Colors.amber, size: 14)),
                              ),
                              Text(r["review"] ?? ""),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
