import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../controllers/database/db_helper.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/AdminHeader_bar.dart';

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

  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.user['username']);
    emailController = TextEditingController(text: widget.user['email']);
    passwordController = TextEditingController(text: widget.user['password']);
    profilePic = widget.user['profilePic'];
  }

  Future<void> pickProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

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

      await DBHelper.instance.updateUser(widget.user['id'], updatedUser);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔵 Admin Header
          const AdminHeaderSection(),

          /// 🔙 Back Arrow + Title
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                /// BACK BUTTON
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(width: 4),

                const Text(
                  "Edit User",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
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
                              : const AssetImage('assets/profile.jpg')
                          as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: usernameController,
                        decoration:
                        const InputDecoration(labelText: 'Username'),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Username required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Email required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: obscurePassword,
                        validator: (val) =>
                        val == null || val.isEmpty ? 'Password required' : null,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                        ),
                        child: const Text(
                          'Save Changes',
                          style:
                          TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
