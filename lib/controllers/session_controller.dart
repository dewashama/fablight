import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/database/db_helper.dart';

class Session {
  /// Get the current logged-in user's ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  /// Get the full current user object
  static Future<Map<String, dynamic>?> getUser() async {
    final userId = await getUserId();
    if (userId != null) {
      return await DBHelper.instance.getUserById(userId);
    }
    return null;
  }

  /// Get the role of the current user
  static Future<String?> getUserRole() async {
    final user = await getUser();
    return user?['role'] as String?;
  }

  /// ✅ Set the current user ID (needed for login/register)
  static Future<void> setUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
  }

  /// Clear session on logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }
}

