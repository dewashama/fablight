class Post {
  final int id;
  final String caption;
  final String body;
  final String imagePath;
  int likes;

  Post({
    required this.id,
    required this.caption,
    this.body = "",
    this.imagePath = "",
    this.likes = 0,
  });

  factory Post.fromMap(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      caption: json['caption'],
      body: json['body'] ?? "",
      imagePath: json['imagePath'] ?? "",
      likes: json['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "caption": caption,
      "body": body,
      "imagePath": imagePath,
      "likes": likes,
    };
  }
}
