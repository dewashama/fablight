import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../controllers/database/db_helper.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController passController = TextEditingController();

  Map<String, dynamic>? activeUser; // STORE LOGGED-IN USER
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final db = DBHelper.instance;
    final usr = await db.getActiveUser(); // <--- GET LOGGED-IN USER

    setState(() {
      activeUser = usr;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (activeUser == null) {
      return const Scaffold(
        body: Center(child: Text("No active user found")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Delete Account",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Enter your password to confirm deletion",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _deleteAccount,
                child: const Text("Delete Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAccount() async {
    final pass = passController.text.trim();

    if (pass.isEmpty) {
      _show("Please enter your password");
      return;
    }

    final email = activeUser!["email"]; // <--- USE LOGGED-IN USER EMAIL

    final success = await AuthController.deleteAccount(
      email: email,
      password: pass,
      context: context,
    );

    if (!mounted) return;

    if (success) {
      _show("Account deleted");
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    } else {
      _show("Incorrect password");
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
