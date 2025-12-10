import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../controllers/database/db_helper.dart';
import '../models/post.dart';

class PostViewScreen extends StatefulWidget {
  final Post post;

  const PostViewScreen({super.key, required this.post});

  @override
  State<PostViewScreen> createState() => _PostViewScreenState();
}

class _PostViewScreenState extends State<PostViewScreen> {
  int likes = 0;
  List<Map<String, dynamic>> comments = [];
  final TextEditingController commentController = TextEditingController();

  int currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    likes = widget.post.likes;
    loadComments();
  }

  Future loadComments() async {
    final c = await DBHelper.instance.getComments(widget.post.id);
    if (!mounted) return;
    setState(() {
      comments = c;
    });
  }

  Future likePost() async {
    final activeUser = await DBHelper.instance.getActiveUser();
    final userId = activeUser?['id'] as int?;
    if (userId == null) return;

    final liked = await DBHelper.instance.likePost(widget.post.id, userId);
    if (liked) {
      setState(() {
        likes++;
      });
    }
  }

  Future addComment() async {
    if (commentController.text.isEmpty) return;

    final activeUser = await DBHelper.instance.getActiveUser();
    final userId = activeUser?['id'] as int?;

    await DBHelper.instance.addComment(
      postId: widget.post.id,
      comment: commentController.text,
      userId: userId,
    );

    commentController.clear();
    loadComments();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> imagePaths = [];
    if (widget.post.imagePath.isNotEmpty) {
      imagePaths = widget.post.imagePath.split(',');
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Post")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images Carousel
            if (imagePaths.isNotEmpty)
              Column(
                children: [
                  CarouselSlider.builder(
                    itemCount: imagePaths.length,
                    itemBuilder: (context, index, realIndex) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(imagePaths[index]),
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 250,
                      viewportFraction: 1,
                      enableInfiniteScroll: false,
                      onPageChanged: (index, reason) {
                        setState(() {
                          currentImageIndex = index;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(imagePaths.length, (dotIndex) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin:
                        const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentImageIndex == dotIndex
                              ? Colors.blue
                              : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            // Caption
            Text(
              widget.post.caption,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Body
            if (widget.post.body.isNotEmpty)
              Text(
                widget.post.body,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            const SizedBox(height: 12),

            // Likes
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up),
                  onPressed: likePost,
                ),
                Text("$likes likes"),
              ],
            ),
            const Divider(),

            // Add Comment Field (like BookDetailPage review field)
            const Text(
              "Add a Comment",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: "Write a comment",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: addComment,
              child: const Text("Submit Comment"),
            ),
            const SizedBox(height: 16),

            // Comments
            const Text(
              "Comments",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (comments.isEmpty)
              const Text("No comments yet")
            else
              Column(
                children: comments.map((c) {
                  final username = c['username'] ?? "Unknown";
                  final profilePic = c['profilePic'] as Uint8List?;
                  final createdAt = c['createdAt'] ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundImage:
                      profilePic != null ? MemoryImage(profilePic) : null,
                      child:
                      profilePic == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(username),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['comment']),
                        const SizedBox(height: 2),
                        Text(
                          createdAt.toString(),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
