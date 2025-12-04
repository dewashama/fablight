import 'package:flutter/material.dart';
import '../widgets/AdminBottomNavBar.dart';
import '../controllers/database/db_helper.dart';
import 'admin_user_edit_screen.dart';
import '../widgets/AdminHeader_bar.dart';   // ✅ Notifications + Logout

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final users = await DBHelper.instance.getUsers();
    setState(() {
      allUsers = users;
      filteredUsers = users;
    });
  }

  void filterUsers(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredUsers = allUsers.where((user) {
        final username = (user['username'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return username.contains(searchQuery) || email.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// ⬇️ ADMIN HEADER
      body: Column(
        children: [
          const AdminHeaderSection(), // 🔔 Notifications + Logout

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search users by username or email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: filterUsers,
            ),
          ),

          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(child: Text('No users found'))
                : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profilePic'] != null
                        ? MemoryImage(user['profilePic'])
                        : const AssetImage('assets/profile.jpg') as ImageProvider,
                  ),
                  title: Text(user['username'] ?? 'Unknown'),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminUserEditScreen(user: user),
                        ),
                      );
                      fetchUsers();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 0),
    );
  }
}
