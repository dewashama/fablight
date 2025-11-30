import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../controllers/database/db_helper.dart';
import 'package:image_picker/image_picker.dart';

class AdminUserEditScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserEditScreen({super.key, required this.user});

  @override
  State<AdminUserEditScreen> createState() => _AdminUserEditScreenState();
}

class _AdminUserEditScreenState extends State<AdminUserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  Uint8List? profilePic;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.user['username']);
    emailController = TextEditingController(text: widget.user['email']);
    passwordController = TextEditingController(text: widget.user['password']);
    profilePic = widget.user['profilePic'];
  }

  Future<void> pickProfilePic() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        profilePic = bytes;
      });
    }
  }

  void saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedUser = {
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'profilePic': profilePic,
      };

      // Correct usage of DBHelper updateUser
      await DBHelper.instance.updateUser(widget.user['id'], updatedUser);
      Navigator.pop(context);
    }
  }

  void deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.deleteUser(widget.user['id']);
      Navigator.pop(context); // back to users list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        backgroundColor: const Color(0xFF2929BB),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickProfilePic,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profilePic != null
                        ? MemoryImage(profilePic!)
                        : const AssetImage('assets/profile.jpg') as ImageProvider,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Username required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Email required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (val) => val == null || val.isEmpty ? 'Password required' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: deleteUser,
                      child: const Text('Delete User'),
                    ),
                    ElevatedButton(
                      onPressed: saveChanges,
                      child: const Text('Save Changes'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
