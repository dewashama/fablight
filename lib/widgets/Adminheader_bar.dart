
import 'package:flutter/material.dart';
import '../controllers/database/db_helper.dart';
import '../screens/rolepick_screen.dart';
import '../screens/admin_verification_screen.dart';

class AdminHeaderSection extends StatefulWidget {
  const AdminHeaderSection({super.key});

  @override
  State<AdminHeaderSection> createState() => _AdminHeaderSectionState();
}

class _AdminHeaderSectionState extends State<AdminHeaderSection> {
  Map<String, dynamic>? currentUser;
  List<Map<String, dynamic>> notifications = [];
  bool hasUnread = false;

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
    fetchNotifications();

    // Debug: print all notifications
    DBHelper.instance.getAllNotifications().then((value) {
      print("All notifications: $value");
    });
  }


  Future<void> fetchCurrentUser() async {
    final user = await DBHelper.instance.getActiveUser();
    if (user != null) {
      setState(() {
        currentUser = user;
      });
    }
  }

  Future<void> fetchNotifications() async {
    final allNotifications = await DBHelper.instance.getAllNotifications();

    setState(() {
      notifications = allNotifications;
      hasUnread = allNotifications.any((n) => n['isRead'] == 0);
    });
  }



  Future<void> markNotificationRead(int id) async {
    await DBHelper.instance.updateNotificationRead(id);
    fetchNotifications();
  }

  Future<void> markAllRead() async {
    await DBHelper.instance.markAllNotificationsRead();
    fetchNotifications();
  }

  void _openNotificationsDrawer() {
    showGeneralDialog(
      context: context,
      barrierLabel: "Notifications",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 8,
            color: Colors.white,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Notifications",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await DBHelper.instance.markAllNotificationsRead();
                      fetchNotifications();
                      // refresh list
                    },
                    child: const Text("Mark all as read"),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: notifications.isEmpty
                        ? const Center(child: Text("No notifications"))
                        : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final createdAtStr = notification['createdAt'] ?? '';
                        final dateTime = DateTime.tryParse(createdAtStr);
                        final formattedDate = dateTime != null
                            ? "${dateTime.day}/${dateTime.month}/${dateTime.year}  ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"
                            : "Unknown date";

                        final isRead = notification['isRead'] == 1;
                        final tileColor = isRead ? Colors.grey[200] : Colors.white;
                        final textColor = isRead ? Colors.grey[700] : Colors.black;

                        return GestureDetector(
                          onTap: () async {
                            await DBHelper.instance.updateNotificationRead(notification['id']);
                            fetchNotifications();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminVerificationScreen(),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.notifications, color: textColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification['title'] ?? 'No Title',
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                          color: textColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification['message'] ?? '',
                                        style: TextStyle(color: textColor, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }


  Future<void> _logout() async {
    await DBHelper.instance.logoutUser();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RolePickScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            "assets/Fablight (1).png",
            height: 75,
          ),
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                    onPressed: _openNotificationsDrawer,
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined, color: Colors.black),
                onPressed: _logout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
