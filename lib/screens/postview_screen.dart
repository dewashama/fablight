import 'dart:io';
import 'package:flutter/material.dart';
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
  final commentCtrl = TextEditingController();

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
    await DBHelper.instance.likePost(widget.post.id, userId: userId);
    setState(() {
      likes++;
    });
  }

  Future addComment() async {
    if (commentCtrl.text.isEmpty) return;

    final activeUser = await DBHelper.instance.getActiveUser();
    final userId = activeUser?['id'] as int?;

    await DBHelper.instance.addComment(
      postId: widget.post.id,
      comment: commentCtrl.text,
      userId: userId,
    );

    commentCtrl.clear();
    loadComments();
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (widget.post.imagePath.isNotEmpty)
              Image.file(
                File(widget.post.imagePath),
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),

            // Caption
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.post.caption,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // Body (optional)
            if (widget.post.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  widget.post.body,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),

            // Likes
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.thumb_up),
                    onPressed: likePost,
                  ),
                  Text("$likes likes"),
                ],
              ),
            ),

            const Divider(),

            // Comments section title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Text(
                "Comments",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // Comments list
            ListView.builder(
              itemCount: comments.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final c = comments[index];
                final username = c['username'] ?? 'Unknown';
                return ListTile(
                  title: Text(c['comment']),
                  subtitle: Text("$username • ${c['createdAt']}"),
                );
              },
            ),

            // Add comment field
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: addComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
