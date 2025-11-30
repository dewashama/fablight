import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../controllers/database/db_helper.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import 'session_controller.dart'; // session helper

class AuthController {
  /// Registers a new user. Returns true if successful, false if email exists.
  static Future<bool> register({
    required String email,
    required String password,
    required String username,
    required String name,
    Uint8List? profilePic,
    required BuildContext context,
  }) async {
    final db = DBHelper.instance;

    // Check if email already exists
    final existingUser = await db.getUserByEmail(email);
    if (existingUser != null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email already registered.")),
      );
      return false;
    }

    // Register the user
    await db.registerUser(
      email,
      password,
      username: username,
      name: name,
      profilePic: profilePic,
    );

    // Automatically log in the new user
    final newUser = await db.loginUser(email, password);
    if (newUser != null) {
      await Session.setUserId(newUser['id']); // Save session
    }

    if (!context.mounted) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registration successful!")),
    );

    // Navigate to HomeScreen
    if (newUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pop(context);
    }

    return true;
  }

  /// Logs in a user. Returns true if successful, false otherwise.
  static Future<bool> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    final db = DBHelper.instance;
    final res = await db.loginUser(email, password);

    if (res != null) {
      await Session.setUserId(res['id']); // Save session

      if (!context.mounted) return true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return true;
    } else {
      if (!context.mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email or password.")),
      );
      return false;
    }
  }

  /// Changes the user's password. Returns true if successful.
  static Future<bool> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
    required BuildContext context,
  }) async {
    final db = DBHelper.instance;
    final user = await db.loginUser(email, oldPassword);

    if (user == null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Old password is incorrect.")),
      );
      return false;
    }

    await db.updatePassword(email, newPassword);

    if (!context.mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password changed successfully.")),
    );
    return true;
  }

  /// Deletes the user account. Returns true if successful.
  static Future<bool> deleteAccount({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    final db = DBHelper.instance;
    final user = await db.loginUser(email, password);

    if (user == null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password incorrect.")),
      );
      return false;
    }

    await db.deleteUser(email);

    // Clear session after deleting account
    await Session.logout();

    if (!context.mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account deleted successfully.")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );

    return true;
  }

  /// Logs out the current user
  static Future<void> logout(BuildContext context) async {
    await Session.logout();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }
}
