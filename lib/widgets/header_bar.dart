import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../controllers/database/db_helper.dart';

class HeaderSection extends StatefulWidget {
  const HeaderSection({super.key});

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refetch the active user whenever dependencies change (e.g., after logout/login)
    fetchCurrentUser();
  }

  Future<void> fetchCurrentUser() async {
    final user = await DBHelper.instance.getActiveUser(); // ✅ get logged-in user
    if (user != null) {
      setState(() {
        currentUser = user;
      });
    } else {
      setState(() {
        currentUser = null; // fallback if no active user
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT: FABLIGHT LOGO
          Image.asset(
            "assets/Fablight (1).png",
            height: 75,
          ),

          // RIGHT: SETTINGS + PROFILE ICONS
          Row(
            children: [
              /// SETTINGS BUTTON
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.black),
                onPressed: () async {
                  // Navigate to settings and refresh after returning
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  fetchCurrentUser();
                },
              ),

              /// PROFILE AVATAR
              GestureDetector(
                onTap: () {
                  if (currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: currentUser!['id']),
                      ),
                    ).then((_) => fetchCurrentUser()); // refresh when returning
                  }
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: currentUser != null && currentUser!['profilePic'] != null
                      ? MemoryImage(currentUser!['profilePic'])
                      : const AssetImage("assets/profile.jpg") as ImageProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
