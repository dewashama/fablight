import 'package:flutter/material.dart';
import '../screens/admin_users_screen.dart';
import '../screens/admin_books_screen.dart';
import '../screens/admin_posts_screen.dart';
import '../screens/admin_add_notice_screen.dart';
import '../screens/rolepick_screen.dart'; // <-- import role pick screen

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0: // Users
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
        );
        break;

      case 1: // Books
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminBookSearchScreen()),
        );
        break;

      case 2: // Add Notice (center button)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminAddNoticeScreen()),
        );
        break;

      case 3: // Posts
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPostsScreen()),
        );
        break;

      case 4: // Quick Logout
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RolePickScreen()),
              (route) => false, // remove all previous routes
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF0A1A5C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final sideWidth = (width - 65) / 2;

            return Row(
              children: [
                // LEFT SIDE
                SizedBox(
                  width: sideWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navIcon(Icons.group_outlined, 0, context),
                      _navIcon(Icons.menu_book_outlined, 1, context),
                    ],
                  ),
                ),

                // SPACE FOR CIRCLE BUTTON
                const SizedBox(width: 65),

                // RIGHT SIDE
                SizedBox(
                  width: sideWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navIcon(Icons.article_outlined, 3, context),
                      _navIcon(Icons.logout, 4, context), // <-- logout icon
                    ],
                  ),
                ),
              ],
            );
          }),

          // CENTER CIRCULAR BUTTON
          Positioned(
            top: -28,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _onItemTapped(context, 2),
                child: Container(
                  height: 65,
                  width: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border:
                    Border.all(color: const Color(0xFF0A1A5C), width: 5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      size: 35,
                      color: Color(0xFF0A1A5C),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int index, BuildContext context) {
    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      child: Icon(
        icon,
        size: 30,
        color: Colors.white,
      ),
    );
  }
}
