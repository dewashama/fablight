import 'package:flutter/material.dart';
import '../screens/admin_users_screen.dart';
import '../screens/admin_books_screen.dart';
import '../screens/admin_posts_screen.dart';
import '../screens/admin_add_notice_screen.dart';
import '../screens/admin_verification_screen.dart';

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

      case 4: // Verification
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminVerificationScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
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
            // NAV ICONS
            Positioned.fill(
              top: 70 * 0.10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navIcon(Icons.group_outlined, 0, context),
                  _navIcon(Icons.menu_book_outlined, 1, context),
                  const SizedBox(width: 65), // center button gap
                  _navIcon(Icons.article_outlined, 3, context),
                  _navIcon(Icons.verified, 4, context),
                ],
              ),
            ),

            // CENTER ADD BUTTON
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
                      border: Border.all(
                        color: const Color(0xFF0A1A5C),
                        width: 5,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 35,
                      color: Color(0xFF0A1A5C),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index, BuildContext context) {
    final bool selected = (index == currentIndex);

    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: selected ? 34 : 30,
            color: selected ? Colors.white : Colors.white70,
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(top: 2),
            height: 3.5,
            width: selected ? 28 : 0,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF4DB5FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
