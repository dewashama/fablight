// db_helper.dart
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fablight.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Bump version to 17 (was 15). Adjust if you already changed it elsewhere.
    return await openDatabase(
      path,
      version: 17,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }


  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        username TEXT,
        name TEXT,
        profilePic BLOB,
        isLoggedIn INTEGER DEFAULT 0,
        role TEXT DEFAULT 'user'
      )
    ''');

    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        author TEXT NOT NULL,
        cover BLOB NOT NULL,
        filePath TEXT NOT NULL,
        tags TEXT DEFAULT '',
        isApproved INTEGER DEFAULT 0,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        userId INTEGER,
        rating INTEGER NOT NULL,
        review TEXT,
        createdAt TEXT,
        FOREIGN KEY(bookId) REFERENCES books(id),
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');
    await db.execute('''
    CREATE TABLE post_likes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        UNIQUE(postId, userId),
        FOREIGN KEY(postId) REFERENCES posts(id),
    FOREIGN KEY(userId) REFERENCES users(id)
    );
    ''');

    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        caption TEXT NOT NULL,
        body TEXT,
        imagePath TEXT,            -- legacy: kept but ignored for multi-image
        likes INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE post_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        FOREIGN KEY(postId) REFERENCES posts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER NOT NULL,
        comment TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        userId INTEGER,
        username TEXT,
        FOREIGN KEY(postId) REFERENCES posts(id),
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE section_books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sectionId INTEGER NOT NULL,
        bookId INTEGER NOT NULL,
        FOREIGN KEY(sectionId) REFERENCES sections(id),
        FOREIGN KEY(bookId) REFERENCES books(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE notices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image BLOB NOT NULL,
        slot INTEGER NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS book_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filePath TEXT UNIQUE,
        lastPage INTEGER,
        lastEpubCfi TEXT
      )
    ''');

    // create initial admin user (same as before)
    await DBHelper.instance.registerUser(
      'admin@example.com',
      'adminpass',
      username: 'admin',
      name: 'Administrator',
      role: 'admin',
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // preserve all previous upgrade logic
    if (oldVersion < 8) {
      try { await db.execute('ALTER TABLE reviews ADD COLUMN userId INTEGER'); } catch (_) {}
      try { await db.execute('ALTER TABLE reviews ADD COLUMN createdAt TEXT'); } catch (_) {}
    }
    if (oldVersion < 9) {
      try { await db.execute('ALTER TABLE users ADD COLUMN isLoggedIn INTEGER DEFAULT 0'); } catch (_) {}
    }
    if (oldVersion < 10) {
      try { await db.execute('ALTER TABLE comments ADD COLUMN userId INTEGER'); } catch (_) {}
      try { await db.execute('ALTER TABLE comments ADD COLUMN username TEXT'); } catch (_) {}
    }
    if (oldVersion < 11) {
      try { await db.execute('ALTER TABLE books ADD COLUMN userId INTEGER'); } catch (_) {}
    }
    if (oldVersion < 12) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image BLOB NOT NULL,
            slot INTEGER NOT NULL UNIQUE
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 13) {
      try { await db.execute('ALTER TABLE books ADD COLUMN isApproved INTEGER DEFAULT 0'); } catch (_) {}
    }
    if (oldVersion < 14) {
      try { await db.execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'"); } catch (_) {}
    }
    if (oldVersion < 15) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            isRead INTEGER DEFAULT 0
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 16) {
      try {
        await db.execute('ALTER TABLE notifications ADD COLUMN userId INTEGER DEFAULT 1');
      } catch (_) {}
    }

    // NEW: post_images table (added in version 17)
    if (oldVersion < 17) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS post_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            postId INTEGER NOT NULL,
            imagePath TEXT NOT NULL,
            FOREIGN KEY(postId) REFERENCES posts(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }
  }
  // =======================================================
  // NOTIFICATIONS METHODS
  // =======================================================

  // ---------------- NOTIFICATIONS ----------------
  Future<int> addNotification({
    required int userId,
    required String title,
    required String message,
  }) async {
    final db = await database;
    try {
      return await db.insert(
        'notifications',
        {
          'userId': userId,
          'title': title,
          'message': message,
          'createdAt': DateTime.now().toIso8601String(),
          'isRead': 0,
        },
      );
    } catch (e) {
      print('Failed to insert notification: $e');
      rethrow;
    }
  }


  Future<List<Map<String, dynamic>>> getUserNotifications(int userId) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateNotificationRead(int notificationId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final db = await database;
    return await db.query(
      'notifications',
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'isRead = ?',
      whereArgs: [0],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> addVerificationNotification({
    required int userId,
    required String title,
    required String message,
  }) async {
    return await addNotification(
      userId: userId,
      title: title,
      message: message,
    );
  }

  Future<int> markAllNotificationsRead() async {
    final db = await database;
    return await db.update(
      'notifications',
      {'isRead': 1},
    );
  }


// Mark all notifications read for a specific user
  Future<void> markAllNotificationsReadForUser(int userId) async {
    final db = await database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // =======================================================
  // USER METHODS
  // =======================================================

  Future<int> registerUser(
      String email,
      String password, {
        required String username,
        required String name,
        Uint8List? profilePic,
        String role = 'user',  // ⭐ NEW
      }) async {
    final db = await instance.database;
    return await db.insert(
      "users",
      {
        "email": email,
        "password": password,
        "username": username,
        "name": name,
        "profilePic": profilePic,
        "isLoggedIn": 0,
        "role": role,  // ⭐ NEW
      },
    );
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;
    final res = await db.query(
      "users",
      where: "email = ? AND password = ?",
      whereArgs: [email, password],
    );

    if (res.isNotEmpty) {
      await setActiveUser(res.first['id'] as int);
      return res.first;
    }
    return null;
  }

  Future<int?> getActiveUserId() async {
    final db = await instance.database;
    final res = await db.query('users', where: 'isLoggedIn = ?', whereArgs: [1], limit: 1);
    return res.isNotEmpty ? res.first['id'] as int : null;
  }

  Future<Map<String, dynamic>?> getActiveUser() async {
    final db = await instance.database;
    final res = await db.query('users', where: 'isLoggedIn = ?', whereArgs: [1], limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> setActiveUser(int userId) async {
    final db = await instance.database;
    await db.update('users', {'isLoggedIn': 0});
    await db.update('users', {'isLoggedIn': 1}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> logoutUser() async {
    final db = await instance.database;
    await db.update('users', {'isLoggedIn': 0});
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await instance.database;
    final res = await db.query("users", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final res = await db.query("users", where: "email = ?", whereArgs: [email]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateProfile({
    required int id,
    String? username,
    String? name,
    Uint8List? profilePic,
  }) async {
    final db = await instance.database;
    final data = <String, dynamic>{};
    if (username != null) data['username'] = username;
    if (name != null) data['name'] = name;
    if (profilePic != null) data['profilePic'] = profilePic;

    return await db.update(
      "users",
      data,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<int> updatePassword(String email, String newPassword) async {
    final db = await instance.database;
    return await db.update(
      "users",
      {"password": newPassword},
      where: "email = ?",
      whereArgs: [email],
    );
  }

  Future<int> deleteUser(String email) async {
    final db = await instance.database;
    return await db.delete(
      "users",
      where: "email = ?",
      whereArgs: [email],
    );
  }

  Future<int> updateUser(int userId, Map<String, dynamic> newValues) async {
    final db = await instance.database;
    return await db.update(
      'users',
      newValues,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // =======================================================
  // BOOK METHODS
  // =======================================================

  Future<int> insertBook({
    required int userId,
    required String title,
    required String summary,
    required String author,
    required Uint8List coverBytes,
    required String filePath,
    String? tags,
    int isApproved = 0, // ⭐ NEW
  }) async {
    final db = await instance.database;
    return await db.insert(
      "books",
      {
        "userId": userId,
        "title": title,
        "summary": summary,
        "author": author,
        "cover": coverBytes,
        "filePath": filePath,
        "tags": tags ?? "",
        "isApproved": isApproved,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getBooks({String? tagFilter}) async {
    final db = await instance.database;
    if (tagFilter == null || tagFilter.trim().isEmpty) {
      return await db.query("books", where: "isApproved = 1");
    }
    final tag = tagFilter.trim().toLowerCase();
    return await db.rawQuery(
      "SELECT * FROM books WHERE LOWER(tags) LIKE ? AND isApproved = 1",
      ['%$tag%'],
    );
  }

  Future<List<Map<String, dynamic>>> getAllBooks() async {
    final db = await instance.database;
    return await db.query('books', where: 'isApproved = 1', orderBy: 'title ASC');
  }

  Future<List<Map<String, dynamic>>> getPendingBooks() async {
    final db = await instance.database;
    return await db.query("books", where: "isApproved = 0");
  }

  Future<int> approveBook(int bookId) async {
    final db = await instance.database;

    // 1️⃣ Get the book info first
    final bookRes = await db.query("books", where: "id = ?", whereArgs: [bookId], limit: 1);
    if (bookRes.isEmpty) return 0;
    final book = bookRes.first;
    final userId = book['userId'] as int?;
    final title = book['title'] as String?;

    // 2️⃣ Update approval
    final updated = await db.update(
      "books",
      {"isApproved": 1},
      where: "id = ?",
      whereArgs: [bookId],
    );

    // 3️⃣ Send notification to user
    if (userId != null && title != null) {
      await addNotification(
        userId: userId,
        title: "Book Approved",
        message: "Your book \"$title\" has been verified and uploaded.",
      );
    }

    return updated;
  }


  Future<int> rejectBook(int bookId) async {
    final db = await instance.database;

    // Get book info
    final bookRes = await db.query("books", where: "id = ?", whereArgs: [bookId], limit: 1);
    if (bookRes.isEmpty) return 0;
    final book = bookRes.first;
    final userId = book['userId'] as int?;
    final title = book['title'] as String?;

    // Delete or mark rejected
    final updated = await db.update(
      "books",
      {"isApproved": -1}, // optional: -1 for rejected
      where: "id = ?",
      whereArgs: [bookId],
    );

    // Send notification
    if (userId != null && title != null) {
      await addNotification(
        userId: userId,
        title: "Book Rejected",
        message: "Your book \"$title\" has been rejected by the admin.",
      );
    }

    return updated;
  }


  Future<Map<String, dynamic>?> getBookById(int id) async {
    final db = await instance.database;
    final res = await db.query("books", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateBook(int bookId, Map<String, dynamic> newValues) async {
    final db = await database;
    return await db.update(
      'books',
      newValues,
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<int> deleteBook(int bookId) async {
    final db = await database;
    return await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<String?> getBookFilePath(int bookId) async {
    final db = await instance.database;
    final res = await db.query(
      "books",
      columns: ["filePath"],
      where: "id = ?",
      whereArgs: [bookId],
      limit: 1,
    );
    return res.isNotEmpty ? res.first['filePath'] as String : null;
  }
  // =======================================================
  // REVIEWS METHODS
  // =======================================================
  Future<int> addReview({
    required int bookId,
    required int userId,
    required int rating,
    required String review,
  }) async {
    final db = await instance.database;
    return await db.insert(
      "reviews",
      {
        "bookId": bookId,
        "userId": userId,
        "rating": rating,
        "review": review,
        "createdAt": DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getReviews(int bookId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT r.*, u.username, u.profilePic
      FROM reviews r
      LEFT JOIN users u ON r.userId = u.id
      WHERE r.bookId = ?
      ORDER BY r.id DESC
    ''', [bookId]);
  }

  // =======================================================
  // POSTS METHODS
  // =======================================================
  /// Legacy insertPost - kept for compatibility but new code should use insertPostWithImages
  Future<int> insertPost({
    required int userId,
    required String caption,
    String? body,
    String? imagePath,
  }) async {
    final db = await instance.database;
    return await db.insert(
      "posts",
      {
        "userId": userId,
        "caption": caption,
        "body": body ?? "",
        "imagePath": imagePath ?? "",
        "likes": 0,
        "createdAt": DateTime.now().toIso8601String(),
      },
    );
  }

  // db_helper.dart
  Future<bool> likePost(int postId, int userId) async {
    final db = await database;

    try {
      await db.insert(
        'post_likes',
        {'postId': postId, 'userId': userId},
      );

      // Increment post likes count
      final res = await db.query('posts', where: 'id = ?', whereArgs: [postId], limit: 1);
      final currentLikes = res.first['likes'] as int? ?? 0;
      await db.update('posts', {'likes': currentLikes + 1}, where: 'id = ?', whereArgs: [postId]);

      return true; // liked successfully
    } catch (_) {
      return false; // user already liked
    }
  }



  /// Insert post and its multiple images (post_images)
  Future<int> insertPostWithImages({
    required int userId,
    required String caption,
    String? body,
    List<String>? imagePaths,
  }) async {
    final db = await instance.database;
    // Insert post (we keep legacy imagePath blank to avoid confusion)
    final postId = await db.insert(
      'posts',
      {
        'userId': userId,
        'caption': caption,
        'body': body ?? '',
        'imagePath': '', // legacy column left blank for new posts
        'likes': 0,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );

    // Insert image rows
    if (imagePaths != null && imagePaths.isNotEmpty) {
      final batch = db.batch();
      for (final path in imagePaths) {
        batch.insert('post_images', {'postId': postId, 'imagePath': path});
      }
      await batch.commit(noResult: true);
    }

    return postId;
  }

  /// Update a post and optionally replace its images (this will delete old post_images and insert new ones)
  Future<int> updatePostWithImages({
    required int postId,
    Map<String, dynamic>? postValues,
    List<String>? imagePaths,
  }) async {
    final db = await database;

    // Update post columns if provided
    int updated = 0;
    if (postValues != null && postValues.isNotEmpty) {
      updated = await db.update('posts', postValues, where: 'id = ?', whereArgs: [postId]);
    }

    // Replace images: delete existing then insert new
    try {
      await db.delete('post_images', where: 'postId = ?', whereArgs: [postId]);
    } catch (_) {}

    if (imagePaths != null && imagePaths.isNotEmpty) {
      final batch = db.batch();
      for (final path in imagePaths) {
        batch.insert('post_images', {'postId': postId, 'imagePath': path});
      }
      await batch.commit(noResult: true);
    }

    return updated;
  }

  /// Delete post and its images
  Future<int> deletePostWithImages(int postId) async {
    final db = await database;
    // delete images first
    await db.delete('post_images', where: 'postId = ?', whereArgs: [postId]);
    // delete post row
    return await db.delete('posts', where: 'id = ?', whereArgs: [postId]);
  }

  /// Get images for a post
  Future<List<String>> getImagesForPost(int postId) async {
    final db = await database;
    final res = await db.query('post_images', where: 'postId = ?', whereArgs: [postId], orderBy: 'id ASC');
    return res.map((r) => r['imagePath'] as String).toList();
  }

  /// Get posts with associated user info and a list of image paths (imagePaths: List<String>)
  Future<List<Map<String, dynamic>>> getPostsWithImages() async {
    final db = await database;
    final posts = await db.rawQuery('''
      SELECT posts.*, users.username, users.profilePic
      FROM posts
      LEFT JOIN users ON posts.userId = users.id
      ORDER BY posts.createdAt DESC
    ''');

    final List<Map<String, dynamic>> result = [];
    for (final p in posts) {
      final postId = p['id'] as int;
      final images = await getImagesForPost(postId);
      // convert to a mutable map copy and add imagePaths
      final mapCopy = Map<String, dynamic>.from(p);
      mapCopy['imagePaths'] = images; // List<String>
      result.add(mapCopy);
    }

    return result;
  }

  /// Keep your previous getPosts for backward compatibility (returns posts without images list)
  Future<List<Map<String, dynamic>>> getPosts() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT posts.*, users.username, users.profilePic
      FROM posts
      INNER JOIN users ON posts.userId = users.id
      ORDER BY posts.id DESC
    ''');
  }


  // =======================================================
  // COMMENTS METHODS
  // =======================================================
  Future<int> addComment({
    required int postId,
    required String comment,
    int? userId,
  }) async {
    final db = await instance.database;

    String username = "Unknown";
    if (userId != null) {
      final user = await getUserById(userId);
      username = user?['username'] ?? "Unknown";
    }

    return await db.insert(
      "comments",
      {
        "postId": postId,
        "comment": comment,
        "createdAt": DateTime.now().toIso8601String(),
        "userId": userId,
        "username": username,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getComments(int postId) async {
    final db = await instance.database;
    return await db.query(
      "comments",
      where: "postId = ?",
      whereArgs: [postId],
      orderBy: "id ASC",
    );
  }

  // =======================================================
  // SECTIONS METHODS
  // =======================================================
  Future<int> insertSection(String name) async {
    final db = await instance.database;
    return await db.insert('sections', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getSections() async {
    final db = await instance.database;
    return await db.query('sections');
  }

  Future<int> addBookToSection(int sectionId, int bookId) async {
    final db = await instance.database;
    return await db.insert(
      'section_books',
      {'sectionId': sectionId, 'bookId': bookId},
    );
  }

  Future<int> removeBookFromSection(int sectionId, int bookId) async {
    final db = await instance.database;
    return await db.delete(
      'section_books',
      where: 'sectionId = ? AND bookId = ?',
      whereArgs: [sectionId, bookId],
    );
  }

  Future<List<Map<String, dynamic>>> getBooksInSection(int sectionId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT b.*
      FROM books b
      INNER JOIN section_books sb ON b.id = sb.bookId
      WHERE sb.sectionId = ?
    ''', [sectionId]);
  }

  // =======================================================
  // POSTS QUERIES
  // =======================================================
  Future<List<Map<String, dynamic>>> getActiveUserPosts() async {
    final activeUser = await getActiveUser();
    if (activeUser == null) return [];

    final db = await instance.database;
    return await db.rawQuery('''
      SELECT p.*, u.username, u.name, u.profilePic
      FROM posts p
      LEFT JOIN users u ON p.userId = u.id
      WHERE p.userId = ?
      ORDER BY p.createdAt DESC
    ''', [activeUser['id']]);
  }





  // =======================================================
  // GET BOOKS UPLOADED BY ACTIVE USER
  // =======================================================
  Future<List<Map<String, dynamic>>> getMyBooks() async {
    final activeUser = await getActiveUser();
    if (activeUser == null) return [];

    final db = await instance.database;
    return await db.query(
      "books",
      where: "userId = ?",
      whereArgs: [activeUser['id']],
      orderBy: "id DESC",
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  // =======================================================
  // NOTICE METHODS
  // =======================================================
  Future<List<Map<String, dynamic>>> getNotices() async {
    final db = await database;
    final res = await db.query('notices', orderBy: 'slot ASC');
    return res;
  }

  Future<int> addOrUpdateNotice(int slot, Uint8List imageBytes) async {
    final db = await database;
    final existing = await db.query('notices', where: 'slot = ?', whereArgs: [slot]);
    if (existing.isNotEmpty) {
      return await db.update(
        'notices',
        {'image': imageBytes},
        where: 'slot = ?',
        whereArgs: [slot],
      );
    } else {
      return await db.insert('notices', {'slot': slot, 'image': imageBytes});
    }
  }

  Future<List<Map<String, dynamic>>> getPostsByUser(int userId) async {
    final db = await database;
    return await db.query(
      'posts',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }
  Future<void> saveBookProgress(String filePath, int? lastPage, String? lastEpubCfi) async {
    final db = await database;
    await db.insert(
      'book_progress',
      {
        'filePath': filePath,
        'lastPage': lastPage,
        'lastEpubCfi': lastEpubCfi,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getBookProgress(String filePath) async {
    final db = await database;
    final res = await db.query(
      'book_progress',
      where: 'filePath = ?',
      whereArgs: [filePath],
      limit: 1,
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }



}
