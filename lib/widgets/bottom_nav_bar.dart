import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/add_screen.dart';
import '../screens/community_screen.dart';
import '../screens/library_screen.dart';
import '../screens/profile_screen.dart';
import '../controllers/database/db_helper.dart';
import '../controllers/session_controller.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) async {
    if (index == currentIndex) return;

    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;

      case 1: // Search
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
        break;

      case 2: // Add
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AddScreen()),
        );
        break;

      case 3: // Community
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CommunityScreen()),
        );
        break;

      case 4: // Library/Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LibraryScreen(activeUser: {},)),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final sideWidth = (width - 65) / 2;

              return Row(
                children: [
                  SizedBox(
                    width: sideWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _navIcon(Icons.home, 0, context),
                        _navIcon(Icons.search, 1, context),
                      ],
                    ),
                  ),
                  SizedBox(width: 65),
                  SizedBox(
                    width: sideWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _navIcon(Icons.people, 3, context),
                        _navIcon(Icons.bookmark, 4, context),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
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
                    border: Border.all(color: const Color(0xFF0A1A5C), width: 5),
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
