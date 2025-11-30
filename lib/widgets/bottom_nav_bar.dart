import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/add_screen.dart';
import '../screens/community_screen.dart';
import '../screens/library_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final double barHeight;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.barHeight = 50,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;

      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AddScreen()),
        );
        break;

      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CommunityScreen()),
        );
        break;

      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LibraryScreen(activeUser: {}),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return SafeArea(
      top: false,
      child: Container(
        height: barHeight,
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
            // ---------------------------
            // SINGLE ROW FOR ALL NAV ICONS
            // ---------------------------
            Positioned.fill(
              top: barHeight * 0.10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navIcon(Icons.home, 0, context),
                  _navIcon(Icons.search, 1, context),

                  SizedBox(width: 65), // space for central Add button

                  _navIcon(Icons.people, 3, context),
                  _navIcon(Icons.bookmark, 4, context),
                ],
              ),
            ),

            // ---------------------------
            // CENTRAL ADD BUTTON
            // ---------------------------
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

  // ---------------------------
  // NAV ICON WITH UNDERLINE
  // ---------------------------
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
