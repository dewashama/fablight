import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/header_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../controllers/database/db_helper.dart';
import 'bookdetail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> allBooks = [];
  List<Map<String, dynamic>> recommendedBooks = [];
  List<Map<String, dynamic>> newArrivals = [];
  Map<String, dynamic>? activeUser;

  int _currentNotice = 0;
  List<Uint8List> noticeImages = [];

  @override
  void initState() {
    super.initState();
    fetchActiveUserAndBooks();
    fetchNotices();
  }

  Future<void> fetchActiveUserAndBooks() async {
    activeUser = await DBHelper.instance.getActiveUser();

    final db = await DBHelper.instance.database;
    final res = await db.query('books');

    // Only books with cover
    allBooks = res.where((b) => b['cover'] != null).toList();

    // Recommended: exclude books uploaded by active user
    final otherUsersBooks =
    allBooks.where((b) => b['userId'] != activeUser!['id']).toList();
    recommendedBooks = getRandomBooks(otherUsersBooks, 6);

    // New arrivals: latest 6 books by createdAt timestamp
    newArrivals = getNewBooks(allBooks, 6);

    setState(() {});
  }

  Future<void> fetchNotices() async {
    final res = await DBHelper.instance.getNotices();
    setState(() {
      noticeImages = res.map((n) => n['image'] as Uint8List).toList();
    });
  }

  List<Map<String, dynamic>> getRandomBooks(
      List<Map<String, dynamic>> books, int count) {
    final random = Random();
    final booksCopy = List<Map<String, dynamic>>.from(books);
    final result = <Map<String, dynamic>>[];

    while (result.length < count && booksCopy.isNotEmpty) {
      int index = random.nextInt(booksCopy.length);
      result.add(booksCopy[index]);
      booksCopy.removeAt(index);
    }

    return result;
  }

  List<Map<String, dynamic>> getNewBooks(
      List<Map<String, dynamic>> books, int count) {
    final sorted = List<Map<String, dynamic>>.from(books)
      ..sort((a, b) {
        final aTime = a['createdAt'] != null
            ? DateTime.parse(a['createdAt'])
            : DateTime.now();
        final bTime = b['createdAt'] != null
            ? DateTime.parse(b['createdAt'])
            : DateTime.now();
        return bTime.compareTo(aTime);
      });
    return sorted.take(count).toList();
  }

  Widget buildBookCard(Map<String, dynamic> book) {
    final Uint8List coverBytes = book['cover'];
    final title = book['title'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailPage(
              book: book,
              activeUser: activeUser,
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                coverBytes,
                height: 150,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
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
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 10),
            const HeaderSection(),
            const SizedBox(height: 16),

            /// NOTICE BOARD CAROUSEL
            CarouselSlider.builder(
              itemCount: noticeImages.isEmpty ? 3 : noticeImages.length,
              itemBuilder: (context, index, realIndex) {
                if (noticeImages.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: Text(
                        "No notices yet",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                }
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      noticeImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                height: 150,
                viewportFraction: 0.85,
                enlargeCenterPage: true,
                autoPlay: true,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentNotice = index;
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                noticeImages.isEmpty ? 3 : noticeImages.length,
                    (index) => Container(
                  width: 8,
                  height: 8,
                  margin:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                    _currentNotice == index ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "New Arrivals",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: newArrivals.isEmpty
                  ? const Center(child: Text("No new arrivals"))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: newArrivals.length,
                itemBuilder: (context, index) {
                  return buildBookCard(newArrivals[index]);
                },
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "Recommended",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: recommendedBooks.isEmpty
                  ? const Center(child: Text("No recommended books"))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recommendedBooks.length,
                itemBuilder: (context, index) {
                  return buildBookCard(recommendedBooks[index]);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
