import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../controllers/database/db_helper.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController oldPass = TextEditingController();
  final TextEditingController newPass = TextEditingController();

  Map<String, dynamic>? activeUser;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final user = await DBHelper.instance.getActiveUser();

    if (!mounted) return;

    if (user == null) {
      _show("You are not logged in.");
      Navigator.pop(context);
      return;
    }

    setState(() {
      activeUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Change Password",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: activeUser == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Old Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updatePassword,
                child: const Text("Update Password"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updatePassword() async {
    final oldPassword = oldPass.text.trim();
    final newPassword = newPass.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      _show("Please fill all fields");
      return;
    }

    if (activeUser == null) {
      _show("User not found");
      return;
    }

    final email = activeUser!["email"];

    final success = await AuthController.changePassword(
      email: email,
      oldPassword: oldPassword,
      newPassword: newPassword,
      context: context,
    );

    if (!mounted) return;

    if (success) {
      _show("Password updated successfully");
      Navigator.pop(context);
    } else {
      _show("Old password is incorrect");
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
